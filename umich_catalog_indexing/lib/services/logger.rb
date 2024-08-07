S.register(:log_stream) do
  $stdout.sync = true
  $stdout
end

Services.register(:logger) do
  SemanticLogger["Catalog Indexing"]
end

SemanticLogger.add_appender(io: S.log_stream, level: :info) unless ENV["APP_ENV"] == "test"
