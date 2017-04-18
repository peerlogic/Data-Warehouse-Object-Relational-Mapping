require 'active_record'
require 'json'

Dir['./models/*.rb'].each { |file| require_relative file }

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     'localhost',
  username: 'root',
  password: '',
  database: 'data_warehouse'
)

all_task_hash = {}
Task.where(task_type: 'review').each_with_index do |task, index|
  print '.' if index % 10 == 0
  next if task.critiques.count == 0 || !task.id.include?('CV-')
  task_hash = { 'critiques' => [], 
                'sum_score_in_whole_task' => 0,
                '80 quantile score' => 0,
                'max grade for all reviews' => -1 }
  # task -> critique
  uniq_accessor_actor_ids = task.critiques.map(&:assessor_actor_id).uniq
  next if uniq_accessor_actor_ids.nil?
  uniq_accessor_actor_ids.each do |assessor_actor_id|
    critiques_per_assessor = task.critiques.select { |c| c.assessor_actor_id == assessor_actor_id }
    next if critiques_per_assessor.nil?
    uniq_accessee_actor_ids = critiques_per_assessor.map(&:assessee_actor_id).uniq
    uniq_accessee_actor_ids.each do |assessee_actor_id|
      total_score = 0
      critiques_per_assessor_per_assessee = critiques_per_assessor.select { |c| c.assessee_actor_id == assessee_actor_id }
      critique_num = 0
      critiques_per_assessor_per_assessee.each do |critique|
        next if critique.criterion.criterion_type != 'rank' || critique.rank.nil?
        criterion_weight = 1
        total_score += (critique.rank.to_i * criterion_weight)
        critique_num += 1
        if(critique.rank.to_i > task_hash['max grade for all reviews'])
          task_hash['max grade for all reviews'] = critique.rank.to_i                   
        end
      end
      next if total_score == 0
      critique_num = critique_num.zero? ? 1 : critique_num
      # convert assessees from teams to participants
      reviewer_actor_id = ActorParticipant.where(actor_id: assessor_actor_id).first.participant.id
      ActorParticipant.where(actor_id: assessee_actor_id).each do |ap|
        avg_score_from_each_critique = (total_score * 1.0 / critique_num).round(2)
        task_hash['critiques'] << { 'reviewer_actor_id' => reviewer_actor_id,
                                    'reviewee_actor_id' => ap.participant.id,
                                    'score'             => avg_score_from_each_critique}
        if(avg_score_from_each_critique > task_hash['max grade for all reviews'])
          task_hash['max grade for all reviews'] = avg_score_from_each_critique                   
        end
      end
    end
  end
  all_task_hash[task.id] = task_hash
end

all_task_hash.each do |task_id, task_hash|
  score_array = []
  max_grade = (task_hash['max grade for all reviews'].zero? ? 1 : task_hash['max grade for all reviews'])
  sum_score_in_whole_task = 0.0
  task_hash['critiques'].each do |critique|
    grade = (100.0 * (max_grade + 1 - critique['score']) / max_grade).round(2)
    critique['score'] = grade
    sum_score_in_whole_task += grade
    score_array << grade
  end
  score_array.sort!
  task_hash['80 quantile score'] = score_array[(score_array.length * 0.8 - 1).round]
  task_hash['sum_score_in_whole_task'] = sum_score_in_whole_task.round(2)
  File.open("../CV-output/#{task_id}.json", 'w') do |f|
    f.write(JSON.pretty_generate(task_hash))
  end
end