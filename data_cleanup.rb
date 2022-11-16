require 'inferno'

Inferno::Application.finalize!

require 'inferno/repositories/session_data'

TestRun = Inferno::Repositories::TestRuns::Model
TestSession = Inferno::Repositories::TestSessions::Model
SessionData = Inferno::Repositories::SessionData::Model
Request = Inferno::Repositories::Requests::Model
Result = Inferno::Repositories::Results::Model

DRY_RUN = ENV['DRY_RUN'].casecmp? 'true'

SESSION_BATCH_SIZE = 5

def old_session_count
  TestSession
    .where{created_at <= 2.months.ago}
    .count
end

def find_old_session_ids(offset)
  session_query =
    TestSession
      .where{created_at <= 2.months.ago}
      .order(:created_at)
      .limit(SESSION_BATCH_SIZE)
      .offset(offset)

  session_query.map(:id)
end

def destroy_request_bodies_and_headers(session_ids)
  request_ids = Request.where(test_session_id: session_ids).map(:index)

  request_ids.each_slice(10) do |ids|
    headers_query = Inferno::Repositories::Headers.db.where(request_id: ids)
    requests_query = Inferno::Repositories::Requests.db.where(index: ids)

    puts "Deleting #{headers_query.count} headers"
    puts "Deleting #{requests_query.count} request bodies"
    headers_query.delete unless DRY_RUN
    requests_query.update(request_body: nil, response_body: nil) unless DRY_RUN
    sleep 0.3 if DRY_RUN
  end
end

def destroy_non_warning_messages(session_ids)
  ids = Result.where(test_session_id: session_ids).map(:id)

  # result_ids.each_slice(10) do |ids|
    messages_query = Inferno::Repositories::Messages.db.where(result_id: ids).exclude(type: 'warning')
    # results_query = Inferno::Repositories::Results.db.where(id: ids)
    # requests_results_query = Inferno::Application['db.connection'][:requests_results].where(results_id: ids)

    puts "Deleting #{messages_query.count} messages"
    messages_query.delete unless DRY_RUN
    # puts "Deleting #{results_query.count} results"
    # results_query.delete unless DRY_RUN
    # puts "Deleting #{requests_results_query.count} requests_results"
    # requests_results_query.delete unless DRY_RUN
    sleep 0.3 if DRY_RUN
  # end
end

# def destroy_test_runs(session_ids)
#   test_runs_query = TestRun.where(test_session_id: session_ids)

#   puts "Deleting #{test_runs_query.count} test runs"
#   test_runs_query.delete unless DRY_RUN
# end

# def destroy_session_data(session_ids)
#   session_ids.each do |session_id|
#     session_data_query = SessionData.where(test_session_id: session_id)

#     puts "Deleting #{session_data_query.count} session data"
#     session_data_query.delete unless DRY_RUN
#     sleep 0.3 if DRY_RUN
#   end
# end

# def destroy_sessions(session_ids)
#   sessions_query = TestSession.where(id: session_ids)

#   puts "Deleting #{sessions_query.count} test sessions"
#   sessions_query.delete unless DRY_RUN
#   sleep 1 if DRY_RUN
# end

remaining_sessions = old_session_count
offset = 0

loop do
  puts "#{remaining_sessions} left to process."
  session_ids = find_old_session_ids(offset)

  break if session_ids.blank?

  puts "Starting to delete sessions #{session_ids.join(', ')}"
  destroy_request_bodies_and_headers(session_ids)
  destroy_non_warning_messages(session_ids)
  # destroy_test_runs(session_ids)
  # destroy_session_data(session_ids)
  # destroy_sessions(session_ids)
  puts "Finished deleting #{session_ids.length} sessions\n\n"
  offset += SESSION_BATCH_SIZE
  remaining_sessions -= SESSION_BATCH_SIZE
  sleep 5 if DRY_RUN
end
