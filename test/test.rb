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
  SQLCounts.singleton_class.send :attr_accessor, :count
  SQLCounts.count = 0
  module M
    def exec_query *args
      SQLCounts.count += 1
      super
    end
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

c0 = SQLCounts.count
a = Blog.first.as_smart_json(
  owner: :with_image,
  posts: [
    :simple,
    author: :only_name,
    comments: [
      user: [:only_name, :with_image],
    ]
  ]
)
c1 = SQLCounts.count
b = Blog.as_smart_json(
  owner: :with_image,
  posts: [
    :simple,
    author: :only_name,
    comments: [
      user: [:only_name, :with_image],
    ]
  ]
)[0]
c2 = SQLCounts.count
c = Blog.first.as_smart_json(:all)
c3 = SQLCounts.count

class User;def image;profile.image;end;end
ans = Blog.all.includes(
  owner: :profile,
  posts: [
    :author,
    comments: {user: :profile}
  ]
).as_json(
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
)
c4 = SQLCounts.count

errors = []

errors << 'JSON missmatch a b' unless a==b
errors << 'JSON missmatch b c' unless b==c
errors << 'wrong JSON' unless ans[0].to_json == b.to_json.remove(/,"[a-z]+":null/)

errors << "ERR sqlA count: #{c1-c0}" if c1-c0 != 8
errors << "ERR sqlB count: #{c2-c1}" if c2-c1 != 8
errors << "ERR sqlC count: #{c3-c2}" if c3-c2 != 8
errors << "ERR sqlC count: #{c3-c2}" if c4-c3 != 8

owner = a[:owner]
post = a[:posts].first
author = post[:author]
comment = post[:comments].first
user = comment[:user]
erros << ['owner', owner.keys] unless owner.keys == [:image]
erros << ['post', post.keys] unless post.keys == [:title, :author, :comments]
erros << ['author', author.keys] unless author.keys == [:name]
erros << ['comment', comment.keys] unless comment.keys == [:content, :user]
erros << ['user', user.keys] unless user.keys == [:name, :image]

if errors.blank?
  puts :ok
else
  errors.each{|e|p e}
end
Blog.all.as_smart_json(:all)