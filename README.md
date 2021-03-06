![alt tag](/logo.png?raw=true)

# Noventius [![Build Status](https://travis-ci.org/g8labs/noventius.svg?branch=add-travis)](https://travis-ci.org/g8labs/noventius) [![In Progress](https://badge.waffle.io/g8labs/noventius.png?label=In%20Progress&title=In%20Progress)](https://waffle.io/g8labs/noventius)

> A messenger, reporter, courier, bearer of news or tidings

Reporting engine for rails applications

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'noventius'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install noventius
```

## Usage

First we need to create a report. Reports should be placed under `app/reports` and need to inherit from `Noventius::Report`.

```ruby
class UsersReport < Noventius::Report

end
```

Then you need to mount the noventius engine by adding this to the application's config/routes.rb:

```ruby
  mount Noventius::Engine => '/noventius'
```

After that you can access an use the reports by navigating to:
`http://localhost:3000/noventius/reports`

### Query

Reports need to implement the `sql` method, this method should return the SQL query that is going to be performed in the database.

```ruby
class UsersReport < Noventius::Report

  def sql
    <<-SQL
      SELECT *
      FROM users;
    SQL
  end

end
```

### Columns

By default the columns for the report are inferred based on the columns returned by the query and
treated as strings when it comes to display and sorting.
But you can also define in advance what columns the report will have, **If not using custom values
the number of columns defined needs to match the number of elements for every row of the result**,
here is an example:

```ruby
class UsersReport < Noventius::Report

  column :id, :integer, label: 'Id', html_options: { rowspan: 2, colspan: 1 }
  column :name, :string,  label: -> { self.name.to_s.humanize  }
  column :created_at, :datetime

end
```

**Column names need to be unique**

#### Supported types

- string
- integer
- float
- datetime
- date

If you have a column whose type is dynamic, ex: when using the provided `Noventius::Extension::DateQuery`
extension, you can pass a block instead of a symbol for type and the block will be evaluated in the
context of the report when it comes time to render it.

#### Sorting

By default sorting is done based on the value shown in the report but its posible to display
one value and sort by another, this is done with:

```ruby
class UsersReport < Noventius::Report

  column :day, :integer, value: ->(row) { Date::DAYNAMES[row[0]] }, sort_value: ->(row) { row[0] }

end
```

In the given example the report would display the day name but sort it by its place on the week thus
achieving the desired effect.

#### Columns groups

Sometimes we want to group several columns under a common header, this can be done using
columns groups:

```ruby
class UsersReport < Noventius::Report

  column :id, :integer, label: 'Id', html_options: { rowspan: 2, colspan: 1 }
  columns_group :offer_1,
                [column(:event_1, :string, label: 'Event_1'),
                 column(:event_2, :string, label: 'Event_2'),
                 column(:event_3, :string, label: 'Event_3')],
                label: 'Offer_1', html_options: { colspan: 3, rowspan: 1, }

end
```

#### Value for column

By default columns (not including groups) are matched with the rows (after post processing) and
values are taken from that match, but you can also provide custom values for columns by providing
the `:value` option.

```ruby
class UsersReport < Noventius::Report

  column :id, :integer, value: ->(row){ row[0] }

end
```

Default for `:value`: `->(row) { rows[column_index(name.to_sym)] }`

You can provide a block or a symbol, when a symbol is provided that instance method is called on the
report, in both cases the row will be given.

#### Dynamic columns

There are some columns that might depend on the result of the current query in order to be present,
for this case the `dynamic_columns` helper can be used to generate those.

```ruby
class UsersReport < Noventius::Report

  column :id, :integer, label: 'Id', html_options: { rowspan: 2 }
  dynamic_columns :role_users_columns
  column :created_at, :datetime, html_options: { rowspan: 2 }

  filter :role_id, :select, option_tags: :roles_for_select

  def roles_for_select
    [Role.all.collect { |role| [role.name, role.id] }, nil]
  end

  def role_users_columns
    return [] unless role_id

    Role.find(role_id).users.map do |user|
      columns_group(:role_user,
                    [column(:id, :integer),
                     column(:name, :integer)])
                    label: "${user.role.name [#{user.name}]}", html_options: { colspan: 2 })
    end
  end

 end
```

What ever the `role_users_columns` returns will we placed in the columns list in the correct order.

### Filters

Many times, reports need some input from the user. This simple DSL will allow you to add filters in reports easily.

```ruby
class UsersReport < Noventius::Report

  filter :age, :number, options: { min: 18, max: 100 }

  def sql
    <<-SQL
      SELECT *
      FROM users
      WHERE users.age > {age};
    SQL
  end

end
```

This filter call adds a instance method to the report that will return the user input.

A very important thing to notice is that filter DSL wraps on top off rails input helpers so all of them are supported. Full list here: https://github.com/g8labs/noventius/blob/master/lib/noventius/filter.rb#L7

#### Select

The select filter generates a select option using a dropdown.
For this filter you need to provide a method name that when executed returns the
available values for the dropdown.

```ruby
class UsersReport < Noventius::Report

  filter :role_id, :select, option_tags: :roles_for_select

  def roles_for_select
    [Role.all.collect { |role| [role.name, role.id] }, nil]
  end

end
```

##### Supported formats for values
The `option_tags` options can receive one of the following values:
- `Symbol`: When a symbol is given it will execute the instance method with the given name and the returned value will be treated as the new value for the option.
- `Hash`: Only supported when the `dependent` option is being used in the filter.
- `String`: When a string is given it will be treated as raw HTML containing the option tags for the select box.
- `Array`: When an array is given different things will happen depending on it's length.
  - Length 1..2: Rails `options_for_select` will be called with the given array.
  - Length 3..4: Rails `options_from_collection_for_select` will be called with the given array.

##### Supported options
- dependent: This allows to generate selects whose options are dependent from
current selected value from another select. When using this option the only
supported format for the values is a hash.

```ruby
filter :letter, :select, option_tags: :letters_for_select, options: { include_blank: true }
filter :number, :select, option_tags: :numbers_for_select, dependent: :letter, options: { include_blank: 'All' }
filter :symbol, :select, option_tags: :symbols_for_select, dependent: [:letter, :number]

def letters_for_select
  [[:a, :b, :c, :d], nil]
end

def numbers_for_select
  {
    a: [['one', 1],['four', 4], 2],
    b: [2],
    c: [3, 4],
    d: [1, 2, 3]
  }
end

def symbols_for_select
  {
    [:a, 1] => ['$', '%'],
    [:c, 3] => ['@']
  }
end
```

### Nested reports

When the user selects a row its possible to display a new report using data from that row as
filters.
For instance in a report that shows users registrations grouped by month, day or hour, it can be
really helpful that when a user selects a row it shows the registrations for every hour of that
particular day but keeping all other filters.
This can be done using the nested report feature, **only one nested report is supported per report**.

You can customize the options for the nested report by providing either a block or a symbol in the
`:filters` option of the nested report. This method needs to to receive the selected row and can
use the selected filters of the parent report.

```ruby
class UsersReport < Noventius::Report

  filter :start_time, :datetime
  filter :end_time, :datetime
  filter :group_by, :select, option_tags: :groups_for_select

  validate :start_time, rules: { required: true }, messages: { required: 'Provide an start time' }
  validate :end_time, rules: { required: true }, messages: { required: 'Provide an end time' }

  nest_report UsersReport, filters: :nested_filters, if: -> { group_by.present? && grop_by != 'hour' }

  def nested_filters(selected_row)
    selected_date = DateTime.parse(selected_row[3])
    nested_group, start_time, end_time = if group_by == 'month'
                                           ['day', selected_date.at_beginning_of_month.to_s(:db),
                                            selected_date.at_end_of_month.to_s(:db)]
                                         else
                                           ['hour', selected_date.at_beginning_of_day.to_s(:db),
                                            selected_date.at_end_of_day.to_s(:db)]
                                         end

    filter_params.merge('start_time' => start_time, 'end_time' => end_time,
                        'group_by' => nested_group)
  end

  def groups_for_select
    [[:day, :month, :hour], nil]
  end

end
```

Sometimes you will be creating reports that will be only used as nested reports. If you don't want to show
this reports in the menu just add `hidden true` in the report class.

```ruby
class NestedReport < Noventius::Report

  hidden true

end
```

#### Options
- `:filters`: Allows to customize the filters used when creating the nested report.
- `:if`: Used to decide whether or not to enable the nested report.

### Post processors

Its possible to add post processors for the rows, a post processor takes the rows and applies
some transformation to some or all of them and returns the transformed rows. Post processors can
be chained together so each processor can focus on a specific task.

The `post_processor` method takes:
- `Symbol`: When a symbol is given it will execute the instance method with the name passing the
rows as parameter.
- `Proc`: When a block is given it will execute the block in the instance passing the rows as
parameter.
- Anything that responds to `process(report, rows)`: When not a `Symbol` or a `Proc`is provided
what ever is given to the method will need to respond to `process` and take the report and rows as
parameters.

```ruby
class UsersReport < Noventius::Report

  post_processor :parse_dates
  post_processor ->(rows) { FormatDatesPostProcessor.new(1).process(rows) }

  def parse_dates(rows)
    rows.map do |row|
      row[1] = DateTime.parse(row[1])

      row
    end
  end

  class FormatDatesPostProcessor

    def initialize(column_index)
      @column_index = column_index
    end

    def process(rows)
      rows.map do |row|
        # At this point row[@column_index] is a date because of the previous post processor.
        row[@column_index] = row[@column_index].iso8601

        row
      end
    end

  end
end
```

#### Built in post processors
- `Noventius::PostProcessors::DateRanges`: This post processor its used to fill the gaps when the
rows are grouped by: "Day" (day), "Month" (month), "Day of Week" (dow), "Hour" (hour) and "Month of Year" (moy).

##### Example

```ruby
class UsersReport < Noventius::Report

  filter :group_by, :select, option_tags: :groups_for_select

  post_processor ->(rows) { Noventius::PostProcessors::DateRanges.new(:date, group_by).process(self, rows) }

  def groups_for_select
    [[:day, :month, :hour], nil]
  end

end
```

### Validations

It's possible to add client side validations to our filters simply by using the `validate` DSL. For this purpose we use the [jQuery Validation Plugin](https://jqueryvalidation.org) so if you have used it before it will be really easy to get started with it.

##### Example

```ruby
class UsersReport < Noventius::Report

  filter :start_time, :datetime
  filter :end_time, :datetime

  validate :start_time, rules: { required: true }, messages: { required: 'Provide an start time' }
  validate :end_time, rules: { required: true }, messages: { required: 'Provide an end time' }

end
```

The example above specifies that the `start_time` and `end_time` filters are required, and if the validations fails the corresponding error messages will be displayed to the user.

##### Options
- `:rules`: A Hash containing key/value pairs defining custom rules. Key is the rule and value the parameter. [Reference](https://jqueryvalidation.org/validate/#rules)
- `:messages`: A Hash containing key/value pairs defining custom messages. Key is the rule and value the message if the validation fails. [Reference](https://jqueryvalidation.org/validate/#messages)

### Formats

Currently the following formats are supported:
- HTML
- CSV

We have plans on adding JSON in the future.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/g8labs/noventius.

## We are Hiring!

If you are interested in working with us we are happy to talk :). Ping at dev@g8labs.co

## Contact
- Adrian Gomez     - <adrian_g171@hotmail.com>
- Andrés Pache     - <andres.pache@g8labs.co>
- Martín Fernández - <martin.fernandez@g8labs.co>
- Martín García    - <martin.garcia@g8labs.co>
