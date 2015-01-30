require 'pry'
require 'active_record'
require 'active_support/core_ext'

database = './test.sqlite3'
File.unlink database if File.exists? database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: database
)
module SQLCounts
  module M
    def exec_query *args
      SQLCounts.increment_count
      super
    end
  end
  def self.increment_count
    @count = count + 1
  end
  def self.count
    @count ||= 0
    return @count unless block_given?
    before = self.count
    out = yield
    after = self.count
    [after - before, out]
  end
  ActiveRecord::Base.connection.extend M
end

%w(user profile blog post comment).each do |model|
  require_relative "models/#{model}"
end

users = %w(taro jiro saburo).map{|name|User.create name: name}
users.each do |user|
  user.profile = Profile.new(
    image: "#{user.name}.jpg",
    introduction: "my name is #{user.name}"
  )
end
blogs = (1..6).map{|i|Blog.create title: "blog#{i}", slug: "slug#{i}", owner: users[i%(users.size+1)]}
blogs.each do |blog|
  (1..4).each do |i|
    post = blog.posts.create author: users[i%(users.size+1)], title: "post#{i}", content: "hello post #{i}"
    (1..4).each do |i|
      post.comments.create user: users[i%(users.size+1)], content: "comment#{i}"
    end
  end
end
require_relative '../lib/smart_json'
class Blog < ActiveRecord::Base
  smart_json(:all,
    posts: [:simple,
      author: :only_name,
      comments: :with_user
    ]
  ){
    {owner: owner&&{image: owner.profile.try(:image)}}
  }.require(owner: :profile)
end
class Post < ActiveRecord::Base
  smart_json(:simple){{title: title}}
end
class User < ActiveRecord::Base
  smart_json(:only_name){{name: name}}
  smart_json(:with_image){{image: profile.try(:image)}}.require(:profile)
end
class Comment < ActiveRecord::Base
  smart_json(:default){{content: content}}
  smart_json(:with_user, user: [:only_name, :with_image])
end

c0,a0 = SQLCounts.count{
  Blog.first.as_smart_json(
    owner: :with_image,
    posts: [
      :simple,
      author: :only_name,
      comments: [
        user: [:only_name, :with_image],
      ]
    ]
  )
}
c1,a1 = SQLCounts.count{
  Blog.as_smart_json(
    owner: :with_image,
    posts: [
      :simple,
      author: :only_name,
      comments: [
        user: [:only_name, :with_image],
      ]
    ]
  )[0]
}
c2,a2 = SQLCounts.count{
  Blog.first.as_smart_json(:all)
}
c3,a3 = SQLCounts.count{
  Blog.as_smart_json(:all)[0]
}


class User;def image;profile.image;end;end
as_json_option = {
  include: {
    owner: {only: [], methods: :image},
    posts: {
      only: :title,
      include: {
        author: {only: :name},
        comments: {
          only: :content,
          include: {
            user: {only: :name, methods: :image},
          }
        }
      }
    }
  }
}
class User;def image;profile.image;end;end
cans,ans = SQLCounts.count{
  Blog.all.includes(
    owner: :profile,
    posts: [
      :author,
      comments: {user: :profile}
    ]
  ).as_json(as_json_option)
}
cslow, = SQLCounts.count{Blog.all.as_json(as_json_option)}

errors = []

errors << 'JSON missmatch a0 a1' unless a0==a1
errors << 'JSON missmatch a1 a2' unless a1==a2
errors << 'JSON missmatch a2 a3' unless a2==a3
errors << 'wrong JSON' unless ans[0].to_json == a0.to_json.remove(/,"[a-z]+":null/)

errors << "ERR sql0 count: #{c0}" if c0 != 8
errors << "ERR sql1 count: #{c1}" if c1 != 8
errors << "ERR sql2 count: #{c2}" if c2 != 8
errors << "ERR sql3 count: #{c3}" if c3 != 8
errors << "ERR sqlANS count: #{cans}" if cans != 8
errors << "ERR sqlSLOW count: #{cslow}" if cslow == 8

owner = a0[:owner]
post = a0[:posts].first
author = post[:author]
comment = post[:comments].first
user = comment[:user]
errors << ['owner', owner.keys] unless owner.keys == [:image]
errors << ['post', post.keys] unless post.keys == [:title, :author, :comments]
errors << ['author', author.keys] unless author.keys == [:name]
errors << ['comment', comment.keys] unless comment.keys == [:content, :user]
errors << ['user', user.keys] unless user.keys == [:name, :image]

if errors.blank?
  puts :ok
  exit 0
else
  errors.each{|e|p e}
  exit 1
end
