require "canister"
require "semantic_logger"

Services = Canister.new
S = Services

S.register(:subject_heading_remediation_set_id) { ENV["SUBJECT_HEADING_REMEDIATION_SET_ID"] }

require_relative "services/paths"
require_relative "services/logger"
require_relative "services/dbs"
require_relative "services/solr"
require_relative "services/sftp"
