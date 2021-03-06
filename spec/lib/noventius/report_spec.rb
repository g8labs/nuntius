require 'rails_helper'

RSpec.describe Noventius::Report do

  describe '.all' do

    subject { Noventius::Report.all }

    it 'returns all reports' do
      expect(subject).to include(AReport, BReport, HiddenReport)
    end

  end

  describe '.visibles' do

    subject { Noventius::Report.visibles }

    it 'does not return hidden reports' do
      expect(subject).to_not include(HiddenReport)
    end

  end

  describe '#initialize' do

    subject { Noventius::Report.new(filter_params) }

    let(:filter_params) { { foo: :bar } }

    it 'assigns the correct filter_params' do
      expect(subject.filter_params).to eq(filter_params)
    end

  end

  describe '#result' do

    subject { report.result }
    let(:report) { Noventius::Report.new }

    let(:sql) { '' }
    let(:ar_connection) { double(:activerecord_connection) }

    before do
      allow(report).to receive(:sql).and_return(sql)
      allow(ActiveRecord::Base).to receive(:connection).and_return(ar_connection)
      allow(ar_connection).to receive(:exec_query).with(sql)
    end

    it 'executes the SQL query' do
      expect(report).to receive(:sql)
      expect(ar_connection).to receive(:exec_query).with(sql)
      subject
    end

  end

end

describe '#columns' do

  let(:report) do
    Class.new(Noventius::Report) do

      column :date,                         :datetime,  label: 'Date', html_options: { class: 'date' }
      column :offer_hit,                    :integer,   label: -> { name.to_s.humanize }
      column :mobile_verification,          :integer,   label: -> { name.to_s.humanize }
      column :mobile_verification_failure,  :integer,   label: -> { name.to_s.humanize }
      column :mobile_subscription,          :integer,   label: -> { name.to_s.humanize }
      column :mobile_subscription_failure,  :integer,   label: -> { name.to_s.humanize }
      column :conversion_rate,              :string,    label: 'Conversion rate'

      def sql
        User.all.to_sql
      end
    end.new
  end

  it 'returns the expected columns names' do
    expect(report.columns.map(&:name)).to match(%i(date offer_hit mobile_verification
                                                   mobile_verification_failure mobile_subscription
                                                   mobile_subscription_failure conversion_rate))
  end

  it 'returns the expected columns types' do
    expect(report.columns.map { |column| column.type(report) }).to match(%i(datetime integer
                                                                            integer integer integer
                                                                            integer string))
  end

  it 'returns the expected columns labels' do
    expect(report.columns.map(&:label)).to match(['Date', 'Offer hit', 'Mobile verification',
                                                  'Mobile verification failure', 'Mobile subscription',
                                                  'Mobile subscription failure', 'Conversion rate'])
  end

  it 'returns the expected columns html options' do
    expect(report.columns.map(&:html_options)).to match([{ class: 'date' },
                                                         {},
                                                         {},
                                                         {},
                                                         {},
                                                         {},
                                                         {}])
  end

  context 'when using the columns given by the result' do
    let(:report) do
      Class.new(Noventius::Report) do
        def sql
          User.all.to_sql
        end
      end.new
    end

    it 'returns the columns names from the query result' do
      expect(report.columns.map(&:name)).to match(%i(id name role_id created_at updated_at))
    end

    it 'returns string for all column types' do
      expect(report.columns.map { |column| column.type(report) }).to match(%i(string string string
                                                                              string string))
    end

    it 'returns the columns names as labels' do
      expect(report.columns.map(&:label)).to match(%w(id name role_id created_at updated_at))
    end
  end

end

describe '#rows' do

  subject { Noventius::Report.new.rows }

  let(:rows) { [%w(Row1 Row1 Row1), %w(Row2 Row2 Row2)] }
  let(:ar_result) { double(:activerecord_result) }

  before do
    allow_any_instance_of(Noventius::Report).to receive(:result).and_return(ar_result)
    allow(ar_result).to receive(:rows).and_return(rows)
  end

  it 'calls columns on result' do
    expect(ar_result).to receive(:rows)
    subject
  end

  it 'returns the correct values' do
    expect(subject).to eq(rows)
  end

  describe '#to' do

    let(:report) do
      Class.new(Noventius::Report) do

        column :date,                         :datetime,  label: 'Date', html_options: { class: 'date' }
        column :offer_hit,                    :integer,   label: -> { name.to_s.humanize }
        column :mobile_verification,          :integer,   label: -> { name.to_s.humanize }
        column :mobile_verification_failure,  :integer,   label: -> { name.to_s.humanize }
        column :mobile_subscription,          :integer,   label: -> { name.to_s.humanize }
        column :mobile_subscription_failure,  :integer,   label: -> { name.to_s.humanize }
        column :conversion_rate,              :string,    label: 'Conversion rate'

        def sql
          User.all.to_sql
        end
      end.new
    end

    context 'when csv format' do
      it 'returns a valid csv' do
        expect {
          CSV.parse(report.to(:csv))
        }.to_not raise_error
      end
    end

    context 'when an invalid format' do
      it 'raises an error' do
        expect {
          report.to(:invalid)
        }.to raise_error(NotImplementedError)
      end
    end

  end

end
