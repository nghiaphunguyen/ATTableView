Pod::Spec.new do |s|
  s.name         = "NATTableView"
  s.version      = "3.0.3"
  s.summary      = "A lazy way for smart developers to deal with UITableView."

  s.description  = <<-DESC
                  How many times do you have to implement UITableViewDatasource and UITableViewDelegate?
                  Is it boring? And how to deal with different UITableViewCells in one TableView?

                  You're smart so you need to find a smart way to do it.
                  ATTableView is for you, it's easy to display model in UITableView. Also support different UITableViewCells.
                   DESC

  s.homepage     = "https://github.com/tuanphung/ATTableView"

  s.license      = "MIT"

  s.author             = { "Tuan Phung" => "nghiaphunguyen501@gmail.com" }
  s.social_media_url   = "https://github.com/nghiaphunguyen"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/nghiaphunguyen/ATTableView.git", :tag => s.version }
  s.source_files  = "Source/*.swift"

  s.requires_arc = true

end
