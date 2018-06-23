require 'fileutils'

input_dir = ARGV[0] || '.'
output_dir = ARGV[1] || File.join(Dir.home, 'camera')

puts "input dir #{ input_dir }"
puts "output dir #{ output_dir }"

files = Dir[File.join(input_dir, '**', '*.*')]

total = files.count

def exif_creation_date(file)
  creation_date_string = `exiftool -EXIF:CreateDate "#{ file }"`.split(' : ').last
  Time.new(*creation_date_string.split(/[\: ]/))
end

files.each_with_index do |input_file, index|
  print "#{ index + 1 }/#{ total } - #{ input_file }"

  if File.directory?(input_file)
    puts ' > directory, skipping'
    next
  end

  date = File.birthtime(input_file)

  if File.extname(input_file) =~ /^\.mov|avi|mpeg$/i
    # videos
    output_file_prefix = File.join('videos', date.strftime('%Y-%m-%d_%H%M%S_'))
  elsif File.extname(input_file) =~ /^\.jpg|jpeg$/i
    # photos
    date = exif_creation_date(input_file)
    output_file_prefix = File.join('photos', date.strftime('%Y-%m-%d'), date.strftime('%H%M%S_'))
  else
    # other files
    output_file_prefix = File.join('other', date.strftime('%Y-%m-%d_%H%M%S_'))
  end

  output_file = File.join(output_dir, output_file_prefix + File.basename(input_file))

  if File.exists?(output_file)
    if File.size(output_file) == File.size(input_file)
      puts ' > file exists, skipping'
      next
    end
    print " ? #{ output_file } exists and size is different! Press Enter to continue..."
  end

  FileUtils.mkdir_p(File.dirname(output_file))
  FileUtils.cp(input_file, output_file)

  puts " > #{ output_file }"
end

# find path_to_photos -type f -print0
# | xargs -I {} -0 exiftool -EXIF:CreateDate {}
# | ruby -ne 'puts "#{ $_.strip } - #{ Time.new(*$_.split(" : ").last.split(/[\: ]/)) }"'
