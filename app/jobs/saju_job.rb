require 'net/http'
require 'uri'
require 'json'

class SajuJob < ApplicationJob
  queue_as :default

  def perform(user_data)
    Rails.logger.info "🔮 [SajuJob] 시작! 사용자: #{user_data[:name]}"

    # 1. 프롬프트 준비
    prompt = "이름: #{user_data[:name]}, 생년월일: #{user_data[:birth_date]}, 태어난 시간: #{user_data[:birth_time]}, 도시: #{user_data[:city]}. " \
             "이 사람의 오늘의 운세를 사주풀이 관점에서 아주 신비롭고 친절하게(반말), 마크다운 형식으로 5줄 요약해서 말해줘. 한줄 한줄 띄어서 나오게 해줘"

    # 2. Gemini API 설정 (모델: gemini-2.5-flash)
    api_key = ENV["GEMINI_API_KEY"]
    
    # ★핵심★ URL 뒤에 '&alt=sse'를 붙입니다. (Server-Sent Events 모드)
    # 이렇게 하면 데이터가 "data: {...}" 형태로 줄맞춰서 옵니다.
    url_string = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?key=#{api_key}&alt=sse"
    uri = URI(url_string)

    # 3. 요청 본문 준비
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = { contents: [{ parts: [{ text: prompt }] }] }.to_json

    # 4. 마크다운 변환기 준비 (한 번만 생성)
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    markdown_parser = Redcarpet::Markdown.new(renderer)
    
    full_text = ""

    # 5. 스트리밍 시작
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        
        # 에러 체크
        unless response.is_a?(Net::HTTPSuccess)
           Rails.logger.error "🚨 API 에러: #{response.code} #{response.message}"
           Turbo::StreamsChannel.broadcast_update_to("saju_stream", target: "saju_result_box", html: "통신 에러가 발생했습니다. (코드: #{response.code})")
           return
        end

        # 청크 읽기
        response.read_body do |chunk|
          # 6. SSE 데이터 파싱 ("data: " 로 시작하는 줄만 찾음)
          chunk.each_line do |line|
            next unless line.start_with?("data:") # data: 로 시작 안 하면 무시
            
            json_str = line.sub("data:", "").strip # "data:" 글자 제거
            next if json_str.empty?

            begin
              data = JSON.parse(json_str)
              
              # 텍스트 추출
              text_part = data.dig("candidates", 0, "content", "parts", 0, "text")
              
              if text_part
                full_text += text_part
                
                # HTML로 변환
                html_content = markdown_parser.render(full_text)

                sleep 1

                # 7. 화면으로 쏘기 (타타탁!)
                Turbo::StreamsChannel.broadcast_update_to(
                  "saju_stream",
                  target: "saju_result_box",
                  html: html_content
                )
              end
            rescue JSON::ParserError
              # 가끔 마지막 줄에 이상한 게 올 수 있어서 무시
            end
          end
        end
      end
    end






    embed_url = URI("https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}")
    
    embed_response = Net::HTTP.post(
      embed_url,
      {
        model: "models/text-embedding-004",
        content: { parts: [{ text: full_text }] }
        # embedding_config 삭제! (이게 없어도 알아서 768개로 나옵니다)
      }.to_json,
      { 'Content-Type' => 'application/json' }
    )

    if embed_response.code == "200"
      json = JSON.parse(embed_response.body)
      vector_data = json.dig("embedding", "values") 
      
      # 혹시 몰라 크기 확인 로그 추가
      Rails.logger.info "📏 벡터 크기: #{vector_data&.size}" 

      FortuneLog.create!(
        name: user_data[:name],
        content: full_text,
        embedding: vector_data
      )
      Rails.logger.info "💾 [SajuJob] 벡터 저장 완료!"
    else
      Rails.logger.error "🚨 [SajuJob] 벡터 변환 실패: #{embed_response.body}"
    end

    Rails.logger.info "✅ [SajuJob] 완료! 최종 길이: #{full_text.length}"





  end
end