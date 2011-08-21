require 'spec_helper'

describe TextMessage do
  
  context "sets chatter" do
    
    it 'finds the chatter' do
      chatter = Factory(:chatter)
      s = TextMessage.new(chatter.phone, "message")
      s.set_chatter
      s.chatter.should == chatter
    end
    
    it 'creates a chatter' do
      lambda {
      s = TextMessage.new(rand(10000), "message")
      s.set_chatter
    }.should change(Chatter, :count).by(1)
    end
    
  end
  
  context "sets brand and session" do
    before do
      @brand = Factory(:brand)
    end
    
    it "should find_brand" do
      s = TextMessage.new(rand(1000), @brand.name)
      s.find_brand == @brand
    end
    
    it "should not find_brand" do
      s = TextMessage.new(rand(1000), 'something')
      s.find_brand == []
    end
    
    it "should set_brand_by_last_session" do
      @session = Factory(:text_session, :brand => @brand)
      s = TextMessage.new(@session.chatter.phone, @brand.name)
      s.set_brand_by_last_session.should == @brand
    end
    
    it "should return brand set_brand_by_phone if found our number found" do
      @brand.brand_settings.where(:name => "phone_number").first.update_attributes(:setting => 0000000000)
      s = TextMessage.new(0000000001, @brand.name,"text_caster",0000000000)
      s.set_brand_by_phone.should == @brand
    end
    
    it "should return first brand if our number not found" do
      s = TextMessage.new(0000000001, @brand.name,"text_caster",0010000000)
      s.set_brand_by_phone.should == @brand
    end
    
    it "should set_session if chatter has one today" do
      session = Factory(:text_session, :brand => @brand)
      s = TextMessage.new(session.chatter.phone, @brand.name)
      s.set_session.should == session
    end
    
    it "should set_session to a new session if chatter had a session yesterday" do
      session = Factory(:text_session, :brand => @brand)
      session.update_attributes(:created_at => 28.hours.ago)
      lambda {
      s = TextMessage.new(session.chatter.phone, @brand.name)
      }.should change(TextSession, :count).by(1)
    end

    it "should set_session if chatter doesnt have any sessions" do
      chatter = Factory(:chatter)
      lambda {
        s = TextMessage.new(chatter.phone, @brand.name)
      }.should change(TextSession, :count).by(1)
    end
    
  end
  
  context "finds brand, action or tag" do
    before do
      @brand = Factory(:brand)
      @session = Factory(:text_session, :brand => @brand)
      @text_content = Factory(:text_content, :brand => @brand)
    end

    it "should set_action if present" do
      s = TextMessage.new(@session.chatter.phone, @text_content.category.name)
      s.set_action.should == @text_content.category
    end

    it "should set_tag if present" do
      s = TextMessage.new(@session.chatter.phone, @text_content.tag.name)
      s.set_tag.should == @text_content.tag
    end
  end
  
  context "response" do
    before do
      @brand = Factory(:brand)
      @text_content = Factory(:text_content, :brand => @brand)
      @session = Factory(:text_session, :brand => @brand)      
      @history = Factory(:text_history, :text_session => @session, :tag => @text_content.tag)
    end
    
    it 'should return keyword' do
      @brand.welcome.update_attributes(:setting => "text this in")
      s = TextMessage.new(@session.chatter.phone, @brand.name)
      lambda {
        s.is_keyword
      }.should change(TextHistory, :count).by(1)
      s.response.should == "text this in"
    end
    
    it 'should return list' do
      s = TextMessage.new(@session.chatter.phone, "list")
      s.is_list
      s.response.should == s.tag_list.join(", ")
    end
    
    it 'should return list of actions' do
      s = TextMessage.new(@session.chatter.phone, @text_content.tag.name)
      s.tag_actions
      s.actions.should == "#{@text_content.category.name} or get help"
    end
    
    it 'should return list of actions in response' do
      s = TextMessage.new(@session.chatter.phone, @text_content.tag.name)
      lambda {
        s.is_tag
      }.should change(TextHistory, :count).by(1)        
      s.response.should == "Respond with #{@text_content.category.name} or get help"
    end
    
    it 'should return response if tag has a no action category' do
      new_content = Factory(:text_content, :category => Factory(:category, :name => 'no action'), :brand => @brand, :tag =>@text_content.tag)
      s = TextMessage.new(@session.chatter.phone, @text_content.tag.name)
      lambda {
        s.is_tag
      }.should change(TextHistory, :count).by(1)        
      s.response.should == new_content.response
    end
    
    it 'should return text of action when a session is found' do
      s = TextMessage.new(@session.chatter.phone, @text_content.category.name)
      s.action_text
      s.response.should == @text_content.response
    end

    it 'should return text of action when a session is found' do
      s = TextMessage.new(rand(10000), @text_content.category.name)
      s.action_text
      s.response.should == @brand.welcome.setting
    end

    
    
  end
    
  
end