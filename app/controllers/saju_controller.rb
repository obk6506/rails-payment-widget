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
    image_file = params[:image] # 업로드된 파일 객체

    # 2. 프롬프트 준비 (이미지 유무에 따라 멘트 변경)
    base_prompt = "이름: #{name}, 생년월일: #{birth_date}, 시간: #{birth_time}, 도시: #{city}. "
    
    if image_file
      base_prompt += "함께 첨부한 이미지는 나의 관상 또는 손금 사진이야. 이 사진의 특징과 사주 정보를 종합해서 오늘의 운세를 봐줘. "
    else
      base_prompt += "이 사람의 오늘의 운세를 봐줘. "
    end

    prompt = base_prompt + "말투는 신비롭고 다정하게 반말로 하고, 마크다운 형식으로 3줄 요약과 행운의 아이템을 포함해서 예쁘게 작성해줘."

    # 3. Gemini API 요청 데이터 만들기
    api_key = ENV["GEMINI_API_KEY"]
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}"
    
    # 기본 메시지 구조
    parts = [{ text: prompt }]

    # ★ 이미지가 있다면 Base64로 변환해서 추가!
    if image_file
      image_data = Base64.strict_encode64(image_file.read) # 파일을 읽어서 암호화
      mime_type = image_file.content_type # image/jpeg, image/png 등

      # 이미지 파트 추가 (Gemini 규칙)
      parts << {
        inline_data: {
          mime_type: mime_type,
          data: image_data
        }
      }
      
      # 파일을 읽느라 커서가 끝으로 갔으니, 저장을 위해 다시 맨 앞으로 되감기
      image_file.rewind 
    end

    # 4. 전송
    response = HTTParty.post(url,
      headers: { "Content-Type" => "application/json" },
      body: { contents: [{ parts: parts }] }.to_json
    )

    if response.success?
      @result_text = response.parsed_response.dig("candidates", 0, "content", "parts", 0, "text")
      
      # 5. 벡터 저장 및 이미지 저장
      save_log_with_image(name, @result_text, image_file)
    else
      @result_text = "도사님이 사진을 보더니 놀라셨나봐... 다시 시도해줘! (에러: #{response.code}, #{response.body})"
    end
    
    render :index
  end

  def logs
    @logs = FortuneLog.order(created_at: :desc)
  end
  
  private

  def save_log_with_image(name, content, image_file)
    begin
      # 1. 텍스트 임베딩 (벡터 생성)
      api_key = ENV["GEMINI_API_KEY"]
      embed_url = "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}"
      
      response = HTTParty.post(embed_url,
        headers: { "Content-Type" => "application/json" },
        body: {
          model: "models/text-embedding-004",
          content: { parts: [{ text: content }] }
        }.to_json
      )

      vector_data = nil
      if response.success?
        vector_data = response.parsed_response.dig("embedding", "values")
      end

      # 2. DB 저장 + Active Storage로 이미지 붙이기
      log = FortuneLog.create(name: name, content: content, embedding: vector_data)
      
      if image_file
        log.image.attach(image_file) # ★ 여기가 핵심! 마법의 한 줄
      end

    rescue => e
      Rails.logger.error "저장 실패: #{e.message}"
    end
  end
end