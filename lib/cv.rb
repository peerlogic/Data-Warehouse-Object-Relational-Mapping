require 'active_record'
require 'json'

Dir['./models/*.rb'].each { |file| require_relative file }

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     'localhost',
  username: 'root',
  password: '',
  database: 'data_warehouse_remote'
)

Task.where(task_type: 'review').each_with_index do |task, index|
  print '.' if index % 10 == 0
  next if task.critiques.count == 0 || !task.id.include?('CV-')
  task_hash = { 'critiques' => [] }
  # task -> critique
  uniq_accessor_actor_ids = task.critiques.map(&:assessor_actor_id).uniq
  next if uniq_accessor_actor_ids.nil?
  uniq_accessor_actor_ids.each do |assessor_actor_id|
    # TODO: multiple artifact_ids (task.critiques)
    critiques_per_assessor = task.critiques.select { |c| c.assessor_actor_id == assessor_actor_id }
    next if critiques_per_assessor.nil?
    uniq_accessee_actor_ids = critiques_per_assessor.map(&:assessee_actor_id).uniq
    uniq_accessee_actor_ids.each do |assessee_actor_id|
      critiques_per_assessor_per_assessee = critiques_per_assessor.select { |c| c.assessee_actor_id == assessee_actor_id }
      critiques_per_assessor_per_assessee.each do |critique|
        next if critique.criterion.criterion_type != 'rank' || critique.rank.nil?
        # convert assessees from teams to participants
        reviewer_actor_id = ActorParticipant.where(actor_id: assessor_actor_id).first.participant.id
        ActorParticipant.where(actor_id: assessee_actor_id).each do |ap|
          task_hash['critiques'] << { 'reviewer_actor_id' => reviewer_actor_id,
                                      'reviewee_actor_id' => ap.participant.id,
                                      'score'             => critique.rank }
        end
      end
    end
  end
  File.open("../CV-output/#{task.id}.json", 'w') do |f|
    f.write(JSON.pretty_generate(task_hash))
  end
end
