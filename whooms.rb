#whooms.rb
$:.unshift File.dirname(__FILE__) + '/sinatra/sinatra/lib' #sinatra 0.9.1 has send_data
require 'rubygems'
require 'sinatra'
require 'mapscript'

def map_directory 
 "maps/"
end

def count_files
 count = Dir.entries(map_directory).size - 2
end

get '/' do
  @count = count_files
  erb :index
end

post '/upload' do
  @map = params[:file][:filename]
  temp_file = params[:file][:tempfile]
  FileUtils.mv(temp_file.path, File.join(map_directory, @map))
  @count = count_files
  if File.extname(@map).downcase == ".tif" || File.extname(@map).downcase == ".tiff"
    @msg = "Image saved!"
  else
    FileUtils.rm(File.join(map_directory, @map))
    @msg = "File wasn't a geotiff (with .tif or .tiff extension), so wasn't saved."
  end
   erb :show
end

get '/show' do
    @count = count_files
    erb :show_blank
end

get '/show/:map' do
    @count = count_files
    @msg = "WMS links for "+params[:map]
    @map = params[:map]
    erb :show
end

get '/about' do
  "I'm running on Version " + Sinatra::VERSION
end

get '/wms' do
  @map = params["layer"]
  ows = Mapscript::OWSRequest.new
  ok_params = Hash.new
  params.each {|k,v| ok_params[k.upcase] = v }
  [:request, :version, :transparency, :service, :srs, :width, :height, :bbox, :format, :srs].each do |key|
    ows.setParameter(key.to_s, ok_params[key.to_s.upcase]) unless ok_params[key.to_s.upcase].nil?
  end
  ows.setParameter("STYLES", "")
  ows.setParameter("LAYERS", "image")
  ows.setParameter("COVERAGE", "image")
  mapsv = Mapscript::MapObj.new(File.join(map_directory, '/wms.map'))
  mapsv.applyConfigOptions
  mapsv.setMetaData("wms_onlineresource",   "http://" + request.host + "/wms/#{@map}")

  raster = Mapscript::LayerObj.new(mapsv)
  raster.name = "image"
  raster.type = Mapscript::MS_LAYER_RASTER;
  raster.data = File.join(map_directory, @map)

  raster.status = Mapscript::MS_ON
  raster.dump = Mapscript::MS_TRUE
  raster.metadata.set('wcs_formats', 'GEOTIFF')
  raster.metadata.set('wms_title', ("wms from whooms "+@map))
  raster.metadata.set('wms_srs', 'EPSG:4326')
  raster.debug= Mapscript::MS_TRUE

  Mapscript::msIO_installStdoutToBuffer
  result = mapsv.OWSDispatch(ows)
  content_type = Mapscript::msIO_stripStdoutBufferContentType || "text/plain"
  result_data = Mapscript::msIO_getStdoutBufferBytes

  send_data result_data, :type => content_type, :disposition => "inline"
  Mapscript::msIO_resetHandlers
end


use_in_file_templates!

__END__

@@ layout
<html>
<head>WhooMS - the tiny public geotiff wms server</head>
<body>
<h2>WhooMS - the tiny public geotiff wms server</h2>
Files Uploaded So Far <%= @count %> <br /> <br />
<%= yield %>
<hr />
<p>About: Made with Sinatra, Ruby, Mapserver Mapscript by Tim Waters tim@geothings.net <br />
Code available at:</p>
</body>
</html>

@@ index

1.Get geotiff (epsg:4326)<br />
2.Upload<br />
3.Use<br />

<form action="/upload" method="post" enctype="multipart/form-data" >
<input type="file" name = "file" />
<input type="submit" name="submit" value="Upload" />
<br /><a href="/show">Forgotten link?</a> 
<%= @msg %>

@@ show

<%= @msg %> <br />
<a href="/wms?layer=<%=@map%>&request=GetMap&version=1.1.1&styles=&format=image/png&srs=epsg:4326&exceptions=application/vnd.ogc.se_inimage">
This is your WMS link.</a> Make a note of it.<br />
<a href="/show/<%=@map%>">Permalink to this page.</a>

@@ show_blank

No image selected or uploaded, <br />
If you know you uploaded it add a /yourfile.tif to the end of the url.<br />
<a href="/show/exampleonly.tif">For example.</a>

