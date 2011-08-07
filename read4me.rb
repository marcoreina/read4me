require "OCR.rb"

ocr = OCR.new

# 1º passo: Encontrando as linhas

DimensaoEntrada = 10
CorLimite = 128

img = MultiArray.load_ubyte 'Fontes/Arial48.jpg'
img.show
linhas = ocr.encontraLinha img
linhas[0].show


#2º passo: Encontrando as letras
  
letras = Array.new
linhas.each { |l| letras.push ocr.encontraLetra l }
letras.flatten!
letras[0].show

#3º passo: Reconhecer as letras
letrasReconhecidas = Array.new
for i in 0..letras.length-1
  letrasReconhecidas.push ocr.reconhece letras[i]
end
letrasReconhecidas[0..letrasReconhecidas.length-1]





########################################################################
#Possível idéia de como determinar onde o papel está localizado na tela

img = MultiArray.load_ubyte 'input.png'
threshold = 80
components = (img <= threshold).components
#Número de componentes conexos da imagem
n = components.max + 1
#Números de pixels conexos que pretendo considerar
range = 30 ** 2 .. 100 ** 2
#Histogramas de quantos pixels cada componente tem
hist = components.histogram n
mask = hist.between? range.min, range.max

#Pega os índices dos componentes que são candidatos a ser o papel
s = Sequence( INT, n ).indgen.mask(mask).to_a
component = components.eq s[2]
component.conditional(255,0).show

#################RECONHECIMENTO##########################

require "OCR.rb"

ocr = OCR.new


fonte = "Testes/TesteArial30.jpg"
img = MultiArray.load_ubyte fonte
letrasLucida = Array.new
linhas = ocr.encontraLinha img
linhas.each { |l| letrasLucida.push ocr.encontraLetra(l)[0] }
letrasLucida.flatten!

letrasLucida.each { |l| l.show}

letrasReconhecidasRedeNeural = Array.new
letrasReconhecidasRedeNeuralPeso = Array.new 
a = Time.new
for i in 0..letrasLucida.length-1
  letrasReconhecidasRedeNeural.push ocr.reconheceRedeNeural letrasLucida[i]
end
b = Time.new
puts (b-a).to_s
letrasReconhecidasRedeNeural[0..51].each{ |e| puts e[0][0] + "  " + e[1].to_s}
a = Time.new
for i in 0..letrasLucida.length-1
  letrasReconhecidasRedeNeuralPeso.push ocr.reconheceRedeNeuralPeso letrasLucida[i]
end
b = Time.new
puts (b-a).to_s
letrasReconhecidasRedeNeuralPeso[0..51].each{ |e| puts e[0] + "  " + e[1].to_s}