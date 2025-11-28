class FortuneLog < ApplicationRecord
  # pgvector + neighbor 젬에서 제공하는 매크로는 has_neighbors (복수형) 이다.
  # 단수형(has_neighbor)로 적으면 지금처럼 NoMethodError가 발생한다.
  has_neighbors :embedding

  # [추가] 이 모델은 'image'라는 이름의 파일을 하나 가질 수 있다!
  has_one_attached :image
end
