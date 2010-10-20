require 'helper'
require 'lib/activerecord_test_case'

class FinderTest < ActiveRecordTestCase
  # fixtures :topics, :replies, :users, :projects, :developers_projects

  def test_startup
    assert true
    # assert_respond_to_all Topic, %w(per_page paginate paginate_by_sql paginate_by_definition_in_class)
  end

end