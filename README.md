# smart_json
includesしなくてもN+1をちゃんとしてくれるas_jsonぽい奴

Gemfile
```ruby
gem 'smart_json', github: 'tompng/smart_json'
```


sample
```ruby
class Post < ActiveRecord::Base
  smart_json(:simple){{title: title}}
  smart_json(:with_detail, :simple, author: :only_name, comments: :with_user)
end
class User < ActiveRecord::Base
  smart_json(:only_name){{name: name}}
  smart_json(:with_image){{profile: {image: profile.image}}}.require(:profile)
end
class Comment < ActiveRecord::Base
  smart_json(:default){{content: content}}
  smart_json(:with_user, user: [:only_name, :with_image])
end

Blog.as_smart_json(
  owner: :with_image,
  posts: [
    :simple,
    author: :only_name,
    comments: [
      user: [:only_name, :with_image],
    ]
  ]
)

Blog.as_smart_json(
  owner: :with_image,
  posts: :with_detail
)

Post.first.as_smart_json :with_detail
```

bad sample without smart_json
```ruby
Blog.all.includes(
  owner: :profile,
  posts: [
    :author,
    comments: {user: :profile}
  ]
).as_json(
  include: {
    owner: {only: [], include: {profile: {only: :image}}},
    posts: {
      only: :title,
      include: {
        author: {only: :name},
        comments: {
          only: :content,
          include: {
            user: {only: :name, include: {profile: {only: :image}}},
          }
        }
      }
    }
  }
)
```
