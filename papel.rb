require 'rubygems'
require 'hornetseye_v4l2'
require 'hornetseye_xorg'
require 'hornetseye_rmagick'
include Hornetseye


#*************************#
#Variáveis globais        #
#*************************#

#Define a largura/altura da matriz de entrada para a rede neural
DimensaoEntrada = 64.0
Threshold = 128


#*****************************************************


#*************************#
#Métodos                  #
#*************************#

def preparaLetra(letra)
  #Define o fator para não distorcer a letra 
  fatorEscala = letra.width > letra.height ? DimensaoEntrada/letra.width : DimensaoEntrada/letra.height
  letra = letra.to_magick
  letra = letra.scale(fatorEscala)
  letra = letra.to_ubyte
  #Limpeza de ruído
  letra = (letra <= Threshold).conditional(0,255)
  molde = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill! 255
  molde[0..letra.width-1, 0..letra.height-1] = letra
  molde
end


#*****************************************************

def calculaDimensaoMedia(img)
  larguraMedia = 0.0
  alturaMedia = 0.0
  x = lazy( *img.shape ) { |i,j| i }
  y = lazy( *img.shape ) { |i,j| j }
  components = (img <= Threshold).components
  n = components.max
  Sequence( INT, n + 1 ).indgen.to_a.each do |c|
    if c != 0
      component = components.eq c
      box = [ x.mask( component ).range, y.mask( component ).range ]
      larguraMedia += box[0].size
      alturaMedia += box[1].size
    end
  end
  [larguraMedia/ n, alturaMedia/ n]
end

#*****************************************************

def encontraLinha(img)
  linhas = Array.new
  nComponente = 0
  y = lazy( *img.shape ) { |i,j| j }
  components = (img <= Threshold).components
  
  while nComponente != components.range.max
    linhaTopo, linhaPe = nil,nil
    
    begin 
      nComponente += 1
      caracter = components.eq nComponente
      topo = y.mask( caracter ).range.min
      pe = y.mask( caracter ).range.max
      linhaTopo = topo if linhaTopo.nil? or topo < linhaTopo 
      linhaPe = pe if linhaPe.nil? or pe > linhaPe
      linha = components[0..components.width-1, linhaTopo..linhaPe]
    end while nComponente != linha.max
    linhas.push img[0..components.width-1, linhaTopo..linhaPe]
  end
  linhas
end

#*****************************************************

def encontraLetra(linha)
  #Coloco a linha na vertical, dessa forma a ordem dos componentes coincide com a ordem das letras
  letrasEncontradas = Array.new
  linha = linha.to_magick.rotate(90).to_ubyte
  x = lazy( *linha.shape ) { |i,j| i }
  y = lazy( *linha.shape ) { |i,j| j }
  components = (linha <= Threshold).components
  
  #Esse primeiro loop coloca acentos como mesmo componentes da letra a que pertencem
  for nComponente in 1..components.range.max
    letra = components.eq nComponente
    alturaLetra = x.mask(letra).range
    larguraLetra = y.mask(letra).range
    componenteMaximo = components[0..letra.width-1, larguraLetra].max
    #Se existe um outro componente na faixa da largura da letra em questão, então mescla
    if(componenteMaximo != nComponente)
      components[0..letra.width-1, larguraLetra] += letra[0..letra.width-1, larguraLetra].conditional(componenteMaximo - nComponente,0)
    else
      box = [ alturaLetra, larguraLetra ]
      letrasEncontradas.push linha[*box].to_magick.rotate(-90).to_ubyte
    end
  end
  letrasEncontradas
end

#*************************#
#Código Principal         #
#*************************#

img = MultiArray.load_ubyte 'Fontes/Arial.jpg'

letras = Array.new
letras_temp = Array.new
linhas = Array.new
linhas = encontraLinha(img)

linhas.each { |l| letras_temp.push encontraLetra l }

letras_temp.each {|l| letras += l }

for i in 0..letras.length-1
  letras[i] = preparaLetra letras[i]
  letras[i].show
end


#Imagem binária: 0 fundo, 1 letra
i = (a <= 128).conditional(1,0)
#Letra pontuada: -1 fundo, 1 letra
m = (i < 1).conditional(-1,1)

#Labels do alfabeto com suas respectivas matrizes-peso
h1 = { "a" => (MultiArray.ubyte 32, 32).fill! }

h1["a"] = h1["a"] + m

#Simulando uma entrada, após a fase de treinamento
img = MultiArray.load_ubyte 'Fontes/TimesNewRoman.jpg'
components = (img <= 128).components
component = components.eq 10
box = [ x.mask( component ).range, y.mask( component ).range ]
entrada = preparaLetra(img[*box])
i = (entrada <= 128).conditional(1,0)

candidateScore = (h1["a"]*i).sum

idealWeightModelScore = h1["a"].mask(h1["a"] > 0).sum

recognitionQuotient = candidateScore / idealWeightModelScore.to_f



=begin
Sequence( INT, n + 1 ).indgen.to_a.each do |c|
    if c != 0
      component = components.eq c
      box = [ x.mask( component ).range, y.mask( component ).range ]
      end
    end
  end
=end