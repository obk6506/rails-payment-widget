class PaymentsController < ApplicationController
  allow_unauthenticated_access only: %i[index success fail]

  def index
    # 위젯은 '구매자 ID'가 필수입니다.
    # 로그인한 유저라면 user.id를 쓰겠지만, 지금은 랜덤한 문자열을 만듭니다.
    @customer_key = "TEST_CUSTOMER_#{Time.current.to_i}"
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount]

    url = "https://api.tosspayments.com/v1/payments/confirm"
    
    # ⚠️ 중요: 여기에 '결제위젯용 시크릿 키'를 넣으세요! (아까 쓴 거 말고 새거)
    widget_secret_key = ENV["TOSS_SECRET_KEY"]

    authorization = "Basic " + Base64.strict_encode64("#{widget_secret_key}:")

    response = HTTParty.post(url,
      headers: {
        "Authorization" => authorization,
        "Content-Type" => "application/json"
      },
      body: {
        paymentKey: payment_key,
        orderId: order_id,
        amount: amount
      }.to_json
    )

    if response.success?
      Payment.create!(
        order_id: order_id,
        payment_key: payment_key,
        amount: amount,
        status: "success",
        order_name: "토스 티셔츠 외 2건", # 실제로는 params로 받아오거나 DB에서 조회해야 함
        customer_email: "customer123@gmail.com"
      )

      render plain: "위젯 결제 성공! DB 저장 완료. 주문번호: #{order_id}, 금액: #{amount}원"
    else
      render plain: "결제 승인 실패: #{response.body}", status: :bad_request
    end
  end

  def fail
    render plain: "결제 실패: #{params[:message]}"
  end
end