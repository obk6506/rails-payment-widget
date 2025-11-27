class SajuController < ApplicationController
  allow_unauthenticated_access

  def index
    # 입력 화면 보여주는 곳 (그대로 둠)
  end

  # 기존 def result ... 는 지우고 아래 stream으로 교체!
  def stream
    # 1. 입력값 받기
    user_data = {
      name: params[:name],
      birth_date: params[:birth_date],
      birth_time: params[:birth_time],
      city: params[:city]
    }

    # 2. 화면에 일단 "도사님이 명상 중..." 이라고 띄워줌 (진동벨)
    render turbo_stream: turbo_stream.update("saju_result_box", "🙏 도사님이 명상에 잠기셨습니다... (접신 중)")

    # 3. 주방장(Job)에게 "이거 요리해!" 하고 토스하고 끝냄
    SajuJob.perform_later(user_data)
  end

  def logs
    @logs = FortuneLog.order(created_at: :desc)
  end
  
end