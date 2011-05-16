require "OCR.rb"

ocr = OCR.new
linhas = Array.new
letras = Array.new
letras_temp = Array.new

#1º passo: Encontrando as linhas

DimensaoEntrada = 64.0
CorLimite = 128

img = MultiArray.load_ubyte 'Fontes/Arial.jpg'
img.show

y = lazy( *img.shape ) { |i,j| j }

componentes = (img <= CorLimite).components

caracter = componentes.eq 1
caracter.conditional(0,255).show
topo = y.mask( caracter ).range.min
pe = y.mask( caracter ).range.max
linha = img[0..componentes.width-1, topo..pe]
linha.show

#Resultado final do processo
linhas = ocr.encontraLinha img
linhas[0].show

#2º passo: Encontrando as letras
  
linha = linhas[0]
letrasEncontradas = Array.new
linha = linha.to_magick.rotate(90).to_ubyte
linha.show

componentes = (linha <= CorLimite).components
letra = componentes.eq 1
letra.conditional(0,255).show

x = lazy( *linha.shape ) { |i,j| i }
y = lazy( *linha.shape ) { |i,j| j }

alturaLetra = x.mask(letra).range
larguraLetra = y.mask(letra).range

box = [ alturaLetra, larguraLetra ]
letrasEncontradas.push linha[*box].to_magick.rotate(-90).to_ubyte
letrasEncontradas[0].show

#Resultado final do processo
letras = ocr.encontraLetra linhas[0]




#Possível idéia de como determinar onde o papel está localizado na tela.

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
s = Sequence( INT, n ).indgen.mask(mask).to_a
component = components.eq s[2]
component.conditional(255,0).show



















=begin
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




Sequence( INT, n + 1 ).indgen.to_a.each do |c|
    if c != 0
      component = components.eq c
      box = [ x.mask( component ).range, y.mask( component ).range ]
      end
    end
  end

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
=end