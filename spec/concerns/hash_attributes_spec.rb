require 'spec_helper'

describe "Hash Attributes" do
  before(:each) do
    # path = File.dirname(__FILE__) + "/test.sqlite3"
    # File.delete(path) if File.exist?(path)
    # ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: path)

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.create_table :models do |table|
      table.text :__hash_column
      table.integer :length
    end
  end

  let(:model) do
    model = Class.new(ActiveRecord::Base) do
      include HashAttributes
      serialize :__hash_column, Hash
      self.table_name = "models"
    end
    Object.const_set("Model" + SecureRandom.uuid.gsub('-', ''), model)
  end

  context "class methods", :focus do
    subject { model }

    its(:hash_column) { should == "__hash_column" }

    context "change hash_column" do
      let(:alternative_name) { "__alternative_hash_column" }
      before do
        model.hash_column = alternative_name
      end

      its(:hash_column) { should == alternative_name}

      it "should not accept blank" do
        expect { subject.hash_column = "" }.to raise_error(ArgumentError)
      end
    end

    context "extract_attribute_name" do
      it { subject.extract_attribute_name("id").should == "id" }
      it { subject.extract_attribute_name("#").should be_nil }
      it { subject.extract_attribute_name("name").should == "name" }
      it { subject.extract_attribute_name("name=").should == "name" }
      it { subject.extract_attribute_name("name_before_type_cast").should == "name" }
      it { subject.extract_attribute_name("name?").should == "name" }
      it { subject.extract_attribute_name("name_changed?").should == "name" }
      it { subject.extract_attribute_name("name_was").should == "name" }
      it { subject.extract_attribute_name("name_change").should == "name" }
      it { subject.extract_attribute_name("name_will_change!").should == "name" }
      it { subject.extract_attribute_name("name_unknown").should == "name_unknown" }
    end

    context "is_valid_attribute_name?" do
      it { subject.is_valid_attribute_name?("id").should be_true }
      it { subject.is_valid_attribute_name?("#").should be_false }
      it { subject.is_valid_attribute_name?("name").should be_true }
      it { subject.is_valid_attribute_name?("name=").should be_false }
      it { subject.is_valid_attribute_name?("name_before_type_cast").should be_false }
      it { subject.is_valid_attribute_name?("name?").should be_false }
      it { subject.is_valid_attribute_name?("name_changed?").should be_false }
      it { subject.is_valid_attribute_name?("name_was").should be_false }
      it { subject.is_valid_attribute_name?("name_change").should be_false }
      it { subject.is_valid_attribute_name?("name_will_change!").should be_false }
    end

    context "serialize_hash_column_attribute" do
      let(:datetime_str) { DateTime.now.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:datetime) { DateTime.parse(datetime_str) }
      let(:time_str) { datetime.to_time.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:time) { datetime.to_time }
      let(:date_str) { datetime.to_date.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:date) { datetime.to_date }

      it { subject.serialize_hash_column_attribute("attr", datetime).should == datetime_str }
      it { subject.serialize_hash_column_attribute("attr", {datetime: datetime}).should == {"datetime" => datetime_str} }
      it { subject.serialize_hash_column_attribute("attr", {datetime: {datetime: datetime}}).should == {"datetime" => {"datetime" => datetime_str}} }
      it { subject.serialize_hash_column_attribute("attr", [datetime]).should == [datetime_str] }
      it { subject.serialize_hash_column_attribute("attr", [[datetime]]).should == [[datetime_str]] }
      it { subject.serialize_hash_column_attribute("attr", [{datetime: datetime}]).should == [{"datetime" => datetime_str}] }
      it { subject.serialize_hash_column_attribute("attr", time).should == time_str }
      it { subject.serialize_hash_column_attribute("attr", {time: time}).should == {"time" => time_str} }
      it { subject.serialize_hash_column_attribute("attr", {time: {time: time}}).should == {"time" => {"time" => time_str}} }
      it { subject.serialize_hash_column_attribute("attr", [time]).should == [time_str] }
      it { subject.serialize_hash_column_attribute("attr", [[time]]).should == [[time_str]] }
      it { subject.serialize_hash_column_attribute("attr", [{time: time}]).should == [{"time" => time_str}] }
      it { subject.serialize_hash_column_attribute("attr", date).should == date_str }
      it { subject.serialize_hash_column_attribute("attr", {date: date}).should == {"date" => date_str} }
      it { subject.serialize_hash_column_attribute("attr", {date: {date: date}}).should == {"date" => {"date" => date_str}} }
      it { subject.serialize_hash_column_attribute("attr", [date]).should == [date_str] }
      it { subject.serialize_hash_column_attribute("attr", [[date]]).should == [[date_str]] }
      it { subject.serialize_hash_column_attribute("attr", [{date: date}]).should == [{"date" => date_str}] }
    end

    context "deserialize_hash_column_attribute" do
      let(:datetime_str) { DateTime.now.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:datetime) { DateTime.parse(datetime_str) }
      let(:time_str) { datetime.to_time.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:time) { datetime.to_time }
      let(:date_str) { datetime.to_date.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      let(:date) { datetime.to_date }

      it { subject.deserialize_hash_column_attribute("attr", datetime_str).should == datetime }
      it { subject.deserialize_hash_column_attribute("attr", {datetime: datetime_str}).should == {"datetime" => datetime} }
      it { subject.deserialize_hash_column_attribute("attr", {datetime: {datetime: datetime_str}}).should == {"datetime" => {"datetime" => datetime}} }
      it { subject.deserialize_hash_column_attribute("attr", [datetime_str]).should == [datetime] }
      it { subject.deserialize_hash_column_attribute("attr", [[datetime_str]]).should == [[datetime]] }
      it { subject.deserialize_hash_column_attribute("attr", [{datetime: datetime_str}]).should == [{"datetime" => datetime}] }
      it { subject.deserialize_hash_column_attribute("attr", time_str).should == time }
      it { subject.deserialize_hash_column_attribute("attr", {time: time_str}).should == {"time" => time} }
      it { subject.deserialize_hash_column_attribute("attr", {time: {time: time_str}}).should == {"time" => {"time" => time}} }
      it { subject.deserialize_hash_column_attribute("attr", [time_str]).should == [time] }
      it { subject.deserialize_hash_column_attribute("attr", [[time_str]]).should == [[time]] }
      it { subject.deserialize_hash_column_attribute("attr", [{time: time_str}]).should == [{"time" => time}] }
      it { subject.deserialize_hash_column_attribute("attr", date_str).should == date }
      it { subject.deserialize_hash_column_attribute("attr", {date: date_str}).should == {"date" => date} }
      it { subject.deserialize_hash_column_attribute("attr", {date: {date: date_str}}).should == {"date" => {"date" => date}} }
      it { subject.deserialize_hash_column_attribute("attr", [date_str]).should == [date] }
      it { subject.deserialize_hash_column_attribute("attr", [[date_str]]).should == [[date]] }
      it { subject.deserialize_hash_column_attribute("attr", [{date: date_str}]).should == [{"date" => date}] }
    end

    context "define_hash_column_attribute" do
      before do
        subject.define_hash_column_attribute("name")
      end

      it { expect { subject.define_hash_column_attribute("#") }.to raise_error(ArgumentError) }
      it { subject.method_defined?("name").should be_true }
      it { subject.method_defined?("name=").should be_true }
      it { subject.method_defined?("name_before_type_cast").should be_true }
      it { subject.method_defined?("name?").should be_true }
      it { subject.method_defined?("name_changed?").should be_true }
      it { subject.method_defined?("name_was").should be_true }
      it { subject.method_defined?("name_change").should be_true }
      it { subject.method_defined?("name_will_change!").should be_true }

      context "undefine_attribute_method" do
        before do 
          subject.undefine_attribute_method("name")
        end

        it { subject.method_defined?("name").should be_false }
        it { subject.method_defined?("name=").should be_false }
        it { subject.method_defined?("name_before_type_cast").should be_false }
        it { subject.method_defined?("name?").should be_false }
        it { subject.method_defined?("name_changed?").should be_false }
        it { subject.method_defined?("name_was").should be_false }
        it { subject.method_defined?("name_change").should be_false }
        it { subject.method_defined?("name_will_change!").should be_false }        
      end

      context "attribute setter and getter already exist" do
        before do
          subject.class_eval <<-RUBY
            def name
              nil
            end

            def name=(value)
              value
            end
          RUBY
          subject.define_hash_column_attribute("name")
        end

        it { subject.method_defined?("name").should be_true }
        it { subject.method_defined?("name=").should be_true }
        it { subject.method_defined?("name_before_type_cast").should be_true }
        it { subject.method_defined?("name?").should be_true }
        it { subject.method_defined?("name_changed?").should be_true }
        it { subject.method_defined?("name_was").should be_true }
        it { subject.method_defined?("name_change").should be_true }
        it { subject.method_defined?("name_will_change!").should be_true }
      end
    end
  end

  context "initialize", :focus do
    context "ordinary attribute" do
      context "and with no argument" do
        subject do
          record = model.create
          record.length = 123
          record
        end
        its(:length) { should == 123 }
      end

      context "and with argument" do
        subject do
          record = model.create(length: 123)
          record.length = 456
          record.save
          record
        end
        its(:length) { should == 456 }
      end
    end

    context "with block" do
      context "and no arguments" do
        subject do
          model.create do |record|
            record.length = 123
            record.name = "Jacob"
          end
        end

        its(:length) { should == 123 }
        its(:name) { should == "Jacob" }
      end

      context "and arguments" do
        subject do
          model.create(length: 123) do |record|
            record.name = "Jacob"
          end
        end

        its(:length) { should == 123 }
        its(:name) { should == "Jacob" }
      end

      context "and overwrite arguments" do
        subject do
          model.create(length: 123) do |record|
            record.length = 456
            record.name = "Jacob"
          end
        end

        its(:length) { should == 456 }
        its(:name) { should == "Jacob" }
      end
    end
  end

  context "is_valid_hash_column_attribute_name?", :focus do
    subject { model.create({"name" => "Jacob"}) }
    it { subject.is_valid_hash_column_attribute_name?(model.primary_key).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(model.hash_column).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:length).should be_false }
    it { subject.is_valid_hash_column_attribute_name?("#").should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name).should be_true }
    it { subject.is_valid_hash_column_attribute_name?(:name=).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name_before_type_cast).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name?).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name_changed?).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name_was).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name_change).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:name_will_change!).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number).should be_true }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number=).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number_before_type_cast).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number?).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number_changed?).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number_was).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number_change).should be_false }
    it { subject.is_valid_hash_column_attribute_name?(:lucky_number_will_change!).should be_false }
  end

  context "read_attribute", :focus do
    subject { model.create({name: "Jacob", length: 123}) }

    it { subject.read_attribute(:name).should == "Jacob" }
    it { subject.read_attribute(:__hash_column).should == {"name" => "Jacob"} }
    it { subject.read_attribute(:__hash_column).should be_a(ActiveSupport::HashWithIndifferentAccess) }
    it { subject.read_attribute(:length).should == 123 }
    it { subject.read_attribute(:lucky_number).should be_nil }
    its(:name) { should == "Jacob" }
    its(:__hash_column) { should == {"name" => "Jacob"} }
    its(:__hash_column) { should be_a(ActiveSupport::HashWithIndifferentAccess) }
    its(:length) { should == 123 }
    its(:lucky_number) { should be_nil }
    its([:name]) { should == "Jacob" }
    its([:__hash_column]) { should == {"name" => "Jacob"} }
    its([:__hash_column]) { should be_a(ActiveSupport::HashWithIndifferentAccess) }
    its([:length]) { should == 123 }
    its([:lucky_number]) { should be_nil }
    its(["name"]) { should == "Jacob" }
    its(["__hash_column"]) { should == {"name" => "Jacob"} }
    its(["__hash_column"]) { should be_a(ActiveSupport::HashWithIndifferentAccess) }
    its(["length"]) { should == 123 }
    its(["lucky_number"]) { should be_nil }
  end

  context "read_hash_column_attribute", :focus do
    subject { model.create({name: "Jacob", length: 123}) }

    it { subject.read_hash_column_attribute(:name).should == "Jacob" }
    it { subject.read_hash_column_attribute(:__hash_column).should be_nil }
    it { subject.read_hash_column_attribute(:length).should be_nil }
    it { subject.read_hash_column_attribute(:lucky_number).should be_nil }
  end

  context "write_attribute", :focus do
    subject { model.create({name: "Jacob", length: 123}) }

    it { subject.write_attribute(:name, "Martin").should == "Martin" }
    it { subject.write_attribute(model.hash_column, {name: "Martin"}).should == {"name" => "Martin"} }
    it { subject.write_attribute(model.hash_column, {name: "Martin"}).should be_a(ActiveSupport::HashWithIndifferentAccess) }
    it { subject.write_attribute(model.hash_column, {lucky_number: 123}).should == {"lucky_number" => 123} }
    it { subject.write_attribute(model.hash_column, {lucky_number: 123}).should be_a(ActiveSupport::HashWithIndifferentAccess) }
    it { subject.write_attribute(:length, 456).should == 456 }
    it { subject.write_attribute(:name, nil).should be_nil }
    it { (subject[:name] = "Martin").should == "Martin" }
    it { (subject[:__hash_column] = {name: "Martin"}).should == {name: "Martin"} }
    it { (subject[:__hash_column] = {name: "Martin"}).should be_a(Hash) }
    it { (subject[:__hash_column] = {lucky_number: 123}).should == {lucky_number: 123} }
    it { (subject[:__hash_column] = {lucky_number: 123}).should be_a(Hash) }
    it { (subject[:length] = 456).should == 456 }
    it { (subject[:name] = nil).should be_nil }
  end

  context "write_hash_column_attribute", :focus do
    subject { model.create({name: "Jacob", length: 123}) }

    it { subject.write_hash_column_attribute(:name, "Martin").should == "Martin" }
    it { subject.write_hash_column_attribute(model.hash_column, {name: "Martin"}).should == {name: "Martin"} }
    it { subject.write_hash_column_attribute(model.hash_column, {lucky_number: 123}).should == {lucky_number: 123} }
    it { subject.write_hash_column_attribute(:length, 456).should == 456 }
    it { subject.write_hash_column_attribute(:name, nil).should be_nil }
  end

  context "read_attribute_before_type_cast", :focus do
    let(:datetime_str) { DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:datetime) { DateTime.parse(datetime_str) }

    subject { model.create({datetime_str: datetime_str, datetime: datetime}) }

    its(:datetime_str) { should == datetime }
    its(:datetime) { should == datetime }
    its(:datetime_str_before_type_cast) { should == datetime_str }
    its(:datetime_before_type_cast) { should == datetime_str }

    it { subject.read_attribute(:datetime_str).should == datetime }
    it { subject.read_attribute(:datetime).should == datetime }
    it { subject.read_hash_column_attribute(:datetime_str).should == datetime }
    it { subject.read_hash_column_attribute(:datetime).should == datetime }
    it { subject.read_attribute_before_type_cast(:datetime_str).should == datetime_str }
    it { subject.read_attribute_before_type_cast(:datetime).should == datetime_str }
  end

  context "attributes_before_type_cast", :focus do
    let(:datetime_str) { DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:datetime) { DateTime.parse(datetime_str) }

    subject { model.create({datetime_str: datetime_str, datetime: datetime}) }

    its(:attributes_before_type_cast) { should == {"id"=>subject.id, "datetime_str"=>datetime_str, "datetime"=>datetime_str, "length"=>subject.length} }
  end

  context "query_attribute", :focus do
    subject { model.create({name: "Jacob", length: 123}) }

    its(:id?) { should be_true }
    its(:name?) { should be_true }
    its(:length?) { should be_true }
    its(:__hash_column?) { should be_true }
    its(:lucky_number?) { should be_true }
  end

  context "hash_column_attributes", :focus do
    let(:datetime_str) { DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:datetime) { DateTime.parse(datetime_str) }

    subject { model.create({dates: {datetime_str: datetime_str, datetime: datetime}}) }

    its(:hash_column_attributes) { should == {"dates" => {"datetime_str" => datetime, "datetime" => datetime}} }
  end

  context "hash_column_attribute_names", :focus do
    let(:datetime_str) { DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:datetime) { DateTime.parse(datetime_str) }

    subject { model.create({name: "Jacob", lucky_number: 14}) }

    its(:hash_column_attribute_names) { should == ["lucky_number", "name"] }
  end

  context "attribute_names", :focus do
    subject { model.create({name: "Jacob", lucky_number: 14}) }

    its(:attribute_names) { should == ["id", "length", "lucky_number", "name"] }
  end

  context "attributes", :focus do
    subject { model.create({name: "Jacob", lucky_number: 14}) }

    its(:attributes) { should == {"id"=>subject.id, "length"=>subject.length, "lucky_number"=>14, "name"=>"Jacob"} }
  end

  context "column_for_attribute", :focus do
    subject { model.create({name: "Jacob"}) }

    it { subject.column_for_attribute(:id).should be_a(ActiveRecord::ConnectionAdapters::Column) }
    it { subject.column_for_attribute(:length).should be_a(ActiveRecord::ConnectionAdapters::Column) }
    it { subject.column_for_attribute(:name).should be_nil }
    it { subject.column_for_attribute(:lucky_number).should be_nil }
  end

  context "has_attribute?", :focus do
    subject { model.create({name: "Jacob"}) }

    it { subject.has_attribute?(:id).should be_true }
    it { subject.has_attribute?(:length).should be_true }
    it { subject.has_attribute?(:name).should be_true }
    it { subject.has_attribute?(:lucky_number).should be_false }
  end

  context "assign_attributes", :focus do
    subject do
      record = model.create
      record.reload
      record.attributes = {name: "Jacob", length: 123}
      record.save!
      record
    end

    its(:name) { should == "Jacob" }
    its(:length) { should ==  123 }
  end

  context "to_h", :focus do
    subject { model.create({"name" => "Jacob", "length" => 123}) }
    its(:to_h) { should == {"id"=>subject.id, "name"=>"Jacob", "length"=>123} }
    its(:to_h) { should be_a(ActiveSupport::HashWithIndifferentAccess) }
  end

  context "cache_key", :focus do
    subject { model.create({"name" => "Jacob", "length" => 123}) }
    its(:cache_key) { should == "#{model.name.underscore.dasherize}-#{subject.id}-version-#{Digest::MD5.hexdigest(subject.attributes.inspect)}" }
  end

  context "inspect", :focus do
    subject { model.create({"name" => "Jacob", "length" => 123}) }
    its(:inspect) { should == "#<#{subject.class.name} #{subject.attributes.map{ |k, v| "#{k}: #{v.inspect}" }.join(", ")}>" }
  end

  context "delete hash column attribute", :focus do
    subject { model.create({"name" => "Jacob"}) }
    it { subject.delete_hash_column_attribute(:name).should == "Jacob" }
    it { subject.delete_hash_column_attribute(:lucky_number).should be_nil }

    context "already deleted" do
      before do
        subject.delete_hash_column_attribute(:name)
      end

      it { subject.read_attribute(model.hash_column).should == {} }
      it { subject.delete_hash_column_attribute(:name).should be_nil }
    end
  end

  context "reload", :focus do
    subject do
      record = model.create({name: "Jacob"})
      record.name = "Frida"
      record.reload
      record
    end

    its(:name) { should == "Jacob" }
    its(:name_was) { should == "Jacob" }
    its(:name_changed?) { should be_false }
  end

  context "dirty", :focus do
    subject do
      id = model.create({name: "Jacob"}).id
      record = model.uncached { model.find(id) }
      record.name = "Frida"
      record
    end

    its(:name) { should == "Frida" }
    its(:name_was) { should == "Jacob" }
    its(:name_changed?) { should be_true }
  end

  context "attribute methods", :focus do
    subject { model.create({"name" => "Jacob", "lucky_number" => 14}) }

    its(:name) { should == "Jacob" }
    its([:name]) { should == "Jacob" }
    its(["name"]) { should == "Jacob" }
    its(:lucky_number) { should == 14 }
    its([:lucky_number]) { should == 14 }
    its(["lucky_number"]) { should == 14 }
    its(:name_changed?) { should be_false }
    its(:lucky_number_changed?) { should be_false }
    its(:name_was) { should == "Jacob" }
    its(:lucky_number_was) { should == 14 }
    its(:focusname_change) { should be_nil }
    its(:lucky_number_change) { should be_nil }
    its(:__hash_column) { should == {"name" => "Jacob", "lucky_number" => 14} }
    its(:__hash_column_changed?) { should be_false }
    its(:__hash_column_was) { should == {"name" => "Jacob", "lucky_number" => 14} }
    its(:__hash_column_change) { should be_nil }

    context "with changed value" do
      before do
        subject.name = "Martin"
      end      

      its(:name) { should == "Martin" }
      its([:name]) { should == "Martin" }
      its(["name"]) { should == "Martin" }      
      its(:name_changed?) { should be_true }
      its(:lucky_number_changed?) { should be_false }
      its(:name_was) { should == "Jacob" }
      its(:lucky_number_was) { should == 14 }
      its(:name_change) { should == ["Jacob", "Martin"] }
      its(:lucky_number_change) { should be_nil }
      its(:__hash_column) { should == {"name" => "Martin", "lucky_number" => 14} }
      its(:__hash_column_changed?) { should be_true }
      its(:__hash_column_was) { should == {"name" => "Jacob", "lucky_number" => 14} }
      its(:__hash_column_change) { should == [{"name" => "Jacob", "lucky_number" => 14}, {"name" => "Martin", "lucky_number" => 14}] }

      context "saved" do
        before do
          subject.save
        end

        its(:name) { should == "Martin" }
        its([:name]) { should == "Martin" }
        its(["name"]) { should == "Martin" }
        its(:lucky_number) { should == 14 }
        its([:lucky_number]) { should == 14 }
        its(["lucky_number"]) { should == 14 }
        its(:name_changed?) { should be_false }
        its(:lucky_number_changed?) { should be_false }
        its(:name_was) { should == "Martin" }
        its(:lucky_number_was) { should == 14 }
        its(:name_change) { should be_nil }
        its(:lucky_number_change) { should be_nil }
        its(:__hash_column) { should == {"name" => "Martin", "lucky_number" => 14} }
        its(:__hash_column_changed?) { should be_false }
        its(:__hash_column_was) { should == {"name" => "Martin", "lucky_number" => 14} }
        its(:__hash_column_change) { should be_nil }
      end
    end
  end

  context "time, date and datetime attributes", :focus do
    let(:datetime_str) { DateTime.now.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:datetime) { DateTime.parse(datetime_str) }
    let(:time_str) { datetime.to_time.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:time) { datetime.to_time }
    let(:date_str) { datetime.to_date.in_time_zone.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    let(:date) { datetime.to_date }

    subject do
      record = model.create(datetime: datetime, time: time, date: date)
      record.reload
      record
    end

    its(:datetime) { should == datetime }
    its(:time) { should == time }
    its(:date) { should == date }

    it { subject.__hash_column[:datetime].should == datetime_str }
    it { subject.__hash_column[:time].should == time_str }
    it { subject.__hash_column[:date].should == date_str }
  end

  context "respond_to?", :focus do
    subject { model.create(name: "Jacob") }

    it { subject.respond_to?("length").should be_true }
    it { subject.respond_to?("length=").should be_true }
    it { subject.respond_to?("length_before_type_cast").should be_true }
    it { subject.respond_to?("length?").should be_true }
    it { subject.respond_to?("length_changed?").should be_true }
    it { subject.respond_to?("length_was").should be_true }
    it { subject.respond_to?("length_change").should be_true }
    it { subject.respond_to?("length_will_change!").should be_true }


    it { subject.respond_to?("name").should be_true }
    it { subject.respond_to?("name=").should be_true }
    it { subject.respond_to?("name_before_type_cast").should be_true }
    it { subject.respond_to?("name?").should be_true }
    it { subject.respond_to?("name_changed?").should be_true }
    it { subject.respond_to?("name_was").should be_true }
    it { subject.respond_to?("name_change").should be_true }
    it { subject.respond_to?("name_will_change!").should be_true }

    it { subject.respond_to?("age").should be_false }
    it { subject.respond_to?("age=").should be_false }
    it { subject.respond_to?("age_before_type_cast").should be_false }
    it { subject.respond_to?("age?").should be_false }
    it { subject.respond_to?("age_changed?").should be_false }
    it { subject.respond_to?("age_was").should be_false }
    it { subject.respond_to?("age_change").should be_false }
    it { subject.respond_to?("age_will_change!").should be_false }
  end

  context "update_attributes", :focus do
    subject do
      record = model.create
      record.update_attributes(name: "Jacob", lucky_number: 14)
      record
    end

    its(:name) { should == "Jacob" }
    its(:lucky_number) { should == 14 }
  end

  context "update_attribute", :focus do
    subject do
      record = model.create
      record.update_attribute(:name, "Jacob")
      record
    end

    its(:name) { should == "Jacob" }
  end

  context "update_column", :focus do
    subject do
      record = model.create(id: 1)
      record.reload
      record.update_column(:name, "Jacob")
      record
    end

    its(:name) { should == "Jacob" }
  end

  context "update_column", :focus do
    subject do
      id = model.create.id
      model.update_all(name: "Jacob")
      model.uncached { model.find(id) }
    end

    its(:name) { should == "Jacob" }
  end
end
