class FortuneLog < ApplicationRecord
    has_neighbor :embedding # 벡터 검색용 (기존 코드)
    
    # [추가] 이 모델은 'image'라는 이름의 파일을 하나 가질 수 있다!
    has_one_attached :image
  end