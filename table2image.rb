require 'IMGKit'
require 'awesome_print'
require 'epzip'
require 'nokogiri'
require 'open-uri'
require 'securerandom'
require 'ruby-progressbar'
require 'mini_magick'
require_relative 'table_divider'

INPUTDIR      = 'input'
OUTPUTDIR     = 'output'
PATHTOIMAGES  = 'OEBPS/Images'
TMPIMAGES     = 'tmpimages'
TMPDIR        = 'tmp'

IMGKit.configure do |config|
  config.default_options = {
    :quality  => 70,
    :encoding => 'UTF-8',
    :width    => 600
  }
  config.default_format = :jpg
end

progressbar = ProgressBar.create(
  :format => '%a %bᗧ%i %p%% %t',
  :progress_mark  => ' ',
  :remainder_mark => '･',
  :starting_at => 0,
  :total => Dir.glob(File.join(INPUTDIR, "*.epub")).count
)

def image_height image_path
  image = MiniMagick::Image.new(image_path)
  image.height 
end

Dir.glob(File.join(INPUTDIR, "*.epub")).each do |file|
  if !file.to_s.include?("Book_")
    File.rename(file, "#{INPUTDIR}/Book_#{SecureRandom.urlsafe_base64(5)}" << ".epub")
  end
end

def epubs_list
  Dir.glob(File.join(INPUTDIR, "*.epub"))
end

def content_index
  File.join(TMPDIR, 'OEBPS', 'content.opf')
end

def xhtmls_list
  content_list = []
  allowed_content_mime = ['application/xhtml+xml']
  doc = parse_source content_index
  doc.css('item').each do |item|
    if allowed_content_mime.include?(item.attribute('media-type').value)
      content_list << File.join(TMPDIR, 'OEBPS', item.attribute('href').value)
    end
  end
  content_list
end

def add_rendered_tables_to_manifest
  doc = parse_source content_index
  manifest = doc.css('manifest').first
  rendered_tables = Dir.glob(File.join(TMPDIR, PATHTOIMAGES, "rendered_img_*.jpg"))
  rendered_tables = rendered_tables.map{ |path| parts = path.split('/'); new_path = File.join(parts[2], parts[3]); new_path }
  items_to_inject = rendered_tables.map{ |path| '<item href="'<< path << '" id="' << File.basename(path) << '" media-type="image/jpeg" />' }.join("\n")
  manifest << parse_fragment(items_to_inject)
  f = File.open(content_index, 'w')
  f << doc.to_xml; f.close
end

def unpack_epub filepath
  `epunzip "#{filepath}" 'tmp' 2>&1`
end

def pack_epub filepath
  new_path = filepath.split('/').last
  `epzip 'tmp' "#{OUTPUTDIR}/#{new_path}" 2>&1`
end

def cleanup!
  %w(tmp tmpimages).each{ |dir| `rm -r "#{dir}"` }
  `mkdir tmpimages`
end

def parse_fragment fragment
  Nokogiri::HTML::DocumentFragment.parse(fragment)
end

def parse_source filepath
  Nokogiri::XML(File.open(filepath).read, nil, 'UTF-8')
end

def has_table? doc
  doc.css('table').count > 0
end

def clear_messy_xhtml filepath
  `tidy -m -utf8 -i -asxml -q "#{filepath}" 2>&1`
end

def copy_file_to_epub filepath
  new_filename = File.basename filepath
  `cp "#{filepath}" "tmp/#{PATHTOIMAGES}"/"#{new_filename}"`
  new_filename
end

def to_image html
  kit = IMGKit.new(html)
  kit.stylesheets << 'css/bootstrap.min.css'
  kit.stylesheets << 'css/default.css'
  img = kit.to_img
  file = kit.to_file(File.join(TMPIMAGES, "rendered_img_#{SecureRandom.urlsafe_base64(10)}.jpg"))
  file.path
end

def replace_tables_to_imgs page
  doc = parse_source page
  tables = doc.css('table')

  tables.each do |table|

    divided_tables = TableDivider.new(table).perform!
 
    if divided_tables
      rendered_tables = []
      divided_tables.each do |divided_table|
        fragment = parse_fragment divided_table.to_s
        fragment.at_css('table')['class'] = 'table table-bordered'
        path_to_rendered_table = to_image fragment.to_html
        copied_file = copy_file_to_epub path_to_rendered_table
        rendered_tables << copied_file
      end
      
      tables_as_images_to_inject = rendered_tables.map do |t|
        '<img alt="image" class="rendered_table" src="../Images/' << "#{t}" << '" />'
      end.join("")

      imgs_tables = parse_fragment tables_as_images_to_inject.to_s
      table = table.replace imgs_tables

    else
      table['class'] = "table table-bordered"
      path_to_rendered_table = to_image table.to_html
      copied_file = copy_file_to_epub path_to_rendered_table
      img_table = doc.create_element "img"
      img_table['src']    = "../Images/#{copied_file}"
      img_table['alt']    = "image"
      img_table['class']  = "rendered_table"
      table.replace img_table
    end

  end

  doc.css(".rendered_table").wrap('<p class="center" style="margin:0px; padding:0px"></p>')
  doc
end

epubs_list.each do |filepath|

  unpack_epub filepath

  xhtmls_list.each do |xhtml_path|
    doc = parse_source xhtml_path
    if has_table?(doc)
      processed_doc = replace_tables_to_imgs xhtml_path
      f = File.open(xhtml_path, "w"); f << processed_doc.to_s
      f.close
    end
    clear_messy_xhtml xhtml_path
  end

  add_rendered_tables_to_manifest
  pack_epub filepath
  cleanup!

  progressbar.increment

end