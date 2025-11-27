class AddMissingSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
    # 1. 반복 작업 테이블 (에러의 원인!)
    create_table :solid_queue_recurring_tasks do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, limit: 2048
      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority, default: 0
      t.boolean :static, default: true, null: false
      t.text :description
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :key ], unique: true
      t.index [ :static ]
    end

    # 2. 반복 실행 기록 테이블
    create_table :solid_queue_recurring_executions do |t|
      t.references :job, index: { unique: true }, null: false
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false

      t.index [ :task_key, :run_at ], unique: true
    end

    # 외래키 연결 (안전을 위해)
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end