class RegistrationsController < ApplicationController
  # 👇 로그인 안 된 사람도 들어올 수 있게 허용 (이게 없으면 로그인 창으로 튕김)
  allow_unauthenticated_access

  def new
    # 👇 회원가입 폼을 위한 빈 객체 생성
    @user = User.new
  end

  def create
    # 파라미터 받기 (이메일, 비밀번호, 비밀번호 확인)
    @user = User.new(params.require(:user).permit(:email_address, :password, :password_confirmation))

    if @user.save
      # 가입 성공하면 바로 로그인 처리
      start_new_session_for @user
      redirect_to root_path, notice: "환영합니다 회원가입 성공!"
    else
      # 가입 실패하면 폼 다시 보여주기
      render :new, status: :unprocessable_entity
    end
  end
end
