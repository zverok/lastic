# Lastic

**UNRELEASED YET. EARLY STAGES**

**Lastic** is an attempt to create not sucking DSL for querying
ElasticSearch from Ruby. It wants to erase complexity and enforce
readability and maintainability of the code.

Lastic (Ластик) means "rubber eraser" in Russian; so its a multi-level
pun on Elastic.

Look and feel:

```ruby
require 'lastic'
include Lastic

Lastic.request.
  query_string('Pride AND prejustice').
  filter(field('author.name').nested => 'Jane Osten').
  from(10..20).
  sort(field('publications.year').desc).
  to_h
# => really long hash, which is correct ElasticSearch request you can
#    further pass to any ES client you prefer
```

## Design goals and features

* Lastic tries to look _natural without explanation_;
* Lastic tries to be a thin wrapper;
* It also adds convinience tricks and shortcuts here and there (fun we love);
* It tries to help creating error-prone queries, correct by design;
* It tries to make query creation chainable, so you can split it to several
  aspects, and say `request.query(myfield: 'value)` here and add
  `request.query(otherfield: 'othervalue')` there.

For most of filter/query types, Lastic enforces `field => condition` order:

For example: ES Range query in JSON:

```json
{
  "range" : {
    "age" : {
      "gte" : 10,
      "lte" : 20,
    }
  }
}
```

Same condition in Lastic:

```ruby
# most verbose form
field(:age).range(gte: 10, lte: 20)

# short and clean form, in context of request:
request.query(age: (10..20))
```

TODO: more to write here!

**Caution!**
* We use ElasticSearch for a limited set of tasks. This design works for
  them. Maybe for yours it will not at all.
* Lastic is in early stages of development and it is definitely NOT feature-
  complete, though targeting it.

## Usage

**HIGHLY INCOMPLETE**

### Aggregations

```ruby
# ...
# simple
request.aggs(platforms: Aggs.terms(field: 'platform.id'))

# can be unnamed: Lastic generates the name for you
request.aggs(Aggs.terms(field: 'platform.id'))

# with sub-aggregations:
request.aggs(platforms: Aggs.terms(field: 'platform.id').aggs(sample: Aggs.top_hits(size: 1)))

# can be chained:
request.
  aggs(Aggs.terms(field: 'platform.id')).
  aggs(Aggs.avg(field: 'weight')
# now request have two separate aggregations

# any aggregation can be updated:
request = request.aggs(platforms: Aggs.terms(field: 'platform.id'))
request.aggs[:platforms].aggs!(sample: Aggs.top_hits(size: 1))
# now "platforms" aggregation have "sample" sub-aggregation

# possible further improvements: specialized constructors for common aggs:
request.aggs(platforms: Aggs.terms('platform.id')) # without {field: ...}
```

## Roadmap

* Most of popular ElasticSearch queries, filters, their options and request
  variants should be implemented;
* Aggregations should be implemented;
* There expected to be `Lastic::Search`, which is basically performable
  request; so, Lastic will became simplistic yet powerful ElasticSearch
  (read-only) client;
* `Lastic::Search` (and may be `Lastic::Request` with right setup) will use
  index's mapping to introspect types and fields, intellectually guess
  which fields should be nested and how, alert on non-existing (mistyped)
  fields and so on.
