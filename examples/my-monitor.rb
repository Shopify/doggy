created_at = Time.parse('2015-01-01 14:00:01').to_i * 1000

query <<-QUERY
  sum(last_1m):sum:Engine.current_thrust.status{status:error}.as_count() < 50
QUERY

obj({
  created_at: created_at,
  id: 100500,
  message: "Houston, we have a problem @pagerduty-Houston",
  name: "Engine thrust",
  query: query,
  type: "query alert"
})
