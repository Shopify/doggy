require_relative '../../test_helper'

class Doggy::Models::DashboardTest < Minitest::Test
  def test_attribute_loading
    fixture   = load_fixture('dashboard.json')
    dashboard = Doggy::Models::Dashboard.new(fixture)

    assert_equal 2473,                        dashboard.id
    assert_equal 'My Dashboard',              dashboard.title
    assert_equal 'An informative dashboard.', dashboard.description
  end

  def test_managed_flag
    first_managed_dashboard  = Doggy::Models::Dashboard.new(title: 'Managed')
    second_managed_dashboard = Doggy::Models::Dashboard.new(title: 'Managed :dog:')
    third_managed_dashboard  = Doggy::Models::Dashboard.new(title: "Managed \xF0\x9F\x90\xB6")

    first_skipped_dashboard  = Doggy::Models::Dashboard.new(title: 'Non-managed :scream:')
    second_skipped_dashboard = Doggy::Models::Dashboard.new(title: "Non-managed \xF0\x9F\x98\xB1")

    assert first_managed_dashboard.managed?
    assert second_managed_dashboard.managed?
    assert third_managed_dashboard.managed?

    refute first_skipped_dashboard.managed?
    refute second_skipped_dashboard.managed?
  end

  def test_ensure_managed
    managed_dashboard = Doggy::Models::Dashboard.new(title: 'Managed')
    managed_dashboard.ensure_managed_emoji!

    assert_equal "Managed \xF0\x9F\x90\xB6", managed_dashboard.title
  end
end

