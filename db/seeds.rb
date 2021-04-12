# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)

User.create!(name: "上長1",
             email: "sample1@email.com",
             password: "password",
             password_confirmation: "password",
             superior: true)

User.create!(name: "上長2",
             email: "sample2@email.com",
             password: "password",
             password_confirmation: "password",
             superior: true)

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  employee_number = n+1
  uid = "カードID_#{n+1}"
  User.create!(name: name,
               email: email,
               employee_number: employee_number,
               uid: uid, 
               password: password,
               password_confirmation: password
               )
end

puts 'user作成成功!'