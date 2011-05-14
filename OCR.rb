require 'rubygems'
require 'hornetseye_v4l2'
require 'hornetseye_xorg'
require 'hornetseye_rmagick'
include Hornetseye

#Imagem em P&B
img = MultiArray.load_ubyte 'input.png'
threshold = 80
components = (img <= threshold).components
#Número de componentes conexos da imagem
n = components.max + 1
#Números de pixels conexos que pretendo considerar
range = 30 ** 2 .. 100 ** 2
#Histogramas de quantos pixels cada componente possui
hist = components.histogram n
mask = hist.between? range.min, range.max

#Pega os índices dos componentes que são candidatos a ser o papel
Sequence( INT, n ).indgen.mask(mask).to_a.each do |c|
  component = components.eq c
  #Uma vez já com o componente certo, fazer:
  #x = lazy( *img.shape ) { |i,j| i }
  #y = lazy( *img.shape ) { |i,j| j }
  #box = [ x.mask( component ).range, y.mask( component ).range ]
  
  #Contorno do componente candidato
  edge = component.dilate.and component.erode.not
end