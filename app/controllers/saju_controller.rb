class SajuController < ApplicationController
  allow_unauthenticated_access

  def index
  end

  def stream
    # 1. 입력값 받기
    name = params[:name]
    birth_date = params[:birth_date]
    birth_time = params[:birth_time]
    city = params[:city]

    # 2. 프롬프트 준비
    prompt = "이름: #{name}, 생년월일: #{birth_date}, 시간: #{birth_time}, 도시: #{city}. " \
             "이 사람의 오늘의 운세를 사주풀이 관점에서 아주 신비롭고 친절하게(반말), 마크다운 형식으로 3줄 요약해서 말해줘."

    # 3. Gemini 호출 (한 방에 받기)
    api_key = ENV["GEMINI_API_KEY"]
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}"

    response = HTTParty.post(url,
      headers: { "Content-Type" => "application/json" },
      body: { contents: [{ parts: [{ text: prompt }] }] }.to_json
    )

    if response.success?
      @result_text = response.parsed_response.dig("candidates", 0, "content", "parts", 0, "text")
      
      # 4. 벡터 저장 (성공 시에만)
      save_vector(name, @result_text)
    else
      @result_text = "도사님이 잠시 자리를 비우셨어. 다시 시도해줘! (에러: #{response.code})"
    end
    
    # 5. 결과 화면 보여주기 (index.html.erb를 다시 그림)
    render :index
  end

  private

  def save_vector(name, content)
    # 벡터 변환 및 저장 로직 (백그라운드 없이 바로 실행)
    begin
      api_key = ENV["GEMINI_API_KEY"]
      embed_url = "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}"
      
      response = HTTParty.post(embed_url,
        headers: { "Content-Type" => "application/json" },
        body: {
          model: "models/text-embedding-004",
          content: { parts: [{ text: content }] }
        }.to_json
      )

      if response.success?
        vector_data = response.parsed_response.dig("embedding", "values")
        FortuneLog.create(name: name, content: content, embedding: vector_data)
      end
    rescue => e
      Rails.logger.error "벡터 저장 실패: #{e.message}"
    end
  end
end