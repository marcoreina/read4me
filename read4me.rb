require "OCR.rb"

ocr = OCR.new
linhas = Array.new
letras = Array.new
letras_temp = Array.new

# 1º passo: Encontrando as linhas

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


#Obter todas as letras já preparadas
letras = Array.new
letras_temp = Array.new
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| letras += l }
for i in 0..letras.length-1
  letras[i] = ocr.preparaLetra letras[i]
end

########################################################################
#Possível idéia de como determinar onde o papel está localizado na tela

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
########################################################################


#OUTRA ABORDAGEM - REDE NEURAL SEM PESO

entrada = (MultiArray.int 3, 4).fill!
entrada[0][0] = 1
entrada[1][1] = 1
entrada[2][1] = 1
entrada[3][1] = 1
linha1 = entrada[0..entrada.width-1,0]

coluna = linha1.to_a.join
coluna = coluna.to_i(2)


def aprende(entradas)
  cerebro = Array.new
  4.times { cerebro << []}
  
  for k in 0..entradas.length-1
    entrada = entradas[k]
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      cerebro[i] << mapeamentoBinario
    end
  end
  cerebro.each { |elemento| elemento.uniq!}
  cerebro
end

def sei?(entrada)
  sabedoria = 0.0
  for i in 0..entrada.height-1
    linha = entrada[0..entrada.width-1, i]
    mapeamentoBinario = linha.to_a.join
    if cerebro[i].include? mapeamentoBinario
      sabedoria += 1
  end
  sabedoria/cerebro.length
end




#Teste para possivelmente agilizar o reconhecimento
linha0 = ["a", "g", "h", "z"]
linha1 = ["g", "j", "q"]
linha2 = ["a", "b", "c"]
linha3 = ["a", "r"]

total = linha1 + linha2 + linha3 + linha4

caracter = total.uniq
vezes = []
caracter.each {|e| vezes.push total.count(e)}
resultado = caracter[vezes.index(vezes.max)]







########################################################################
#Teste do redimensionamento e coeficiente de reconhecimento

h = ocr.getLetraAprendida

#TimesNewRoman

nletrasTimes = Array.new
letras_temp = Array.new
letrasTimes = Array.new
img = MultiArray.load_ubyte "Fontes/TimesNewRoman.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTimes += l }
for i in 0..nletrasTimes.length-1
  letrasTimes[i] = ocr.preparaLetra nletrasTimes[i]
end
letrasReconhecidasTimes = Array.new
coeficienteTimes = Array.new
for i in 0..letrasTimes.length-1
  mi = (letrasTimes[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasTimes.push hTemp.index(hTemp.values.max)
  coeficienteTimes.push hTemp.values.max
end

#Calibri

nletrasCalibri = Array.new
letras_temp = Array.new
letrasCalibri = Array.new
img = MultiArray.load_ubyte "Fontes/Calibri.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasCalibri += l }
for i in 0..nletrasCalibri.length-1
  letrasCalibri[i] = ocr.preparaLetra nletrasCalibri[i]
end
letrasReconhecidasCalibri = Array.new
coeficienteCalibri = Array.new
for i in 0..letrasCalibri.length-1
  mi = (letrasCalibri[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasCalibri.push hTemp.index(hTemp.values.max)
  coeficienteCalibri.push hTemp.values.max
end

#Tahoma

nletrasTahoma = Array.new
letras_temp = Array.new
letrasTahoma = Array.new
img = MultiArray.load_ubyte "Fontes/Tahoma.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTahoma += l }
for i in 0..nletrasTahoma.length-1
  letrasTahoma[i] = ocr.preparaLetra nletrasTahoma[i]
end
letrasReconhecidasTahoma = Array.new
coeficienteTahoma = Array.new
for i in 0..letrasTahoma.length-1
  mi = (letrasTahoma[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasTahoma.push hTemp.index(hTemp.values.max)
  coeficienteTahoma.push hTemp.values.max
end

#Arial

nletrasArial = Array.new
letras_temp = Array.new
letrasArial = Array.new
img = MultiArray.load_ubyte "Fontes/Arial.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasArial += l }
for i in 0..nletrasArial.length-1
  letrasArial[i] = ocr.preparaLetra nletrasArial[i]
end
letrasReconhecidasArial = Array.new
coeficienteArial = Array.new
for i in 0..letrasArial.length-1
  mi = (letrasArial[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasArial.push hTemp.index(hTemp.values.max)
  coeficienteArial.push hTemp.values.max
end

#Comic

nletrasComic = Array.new
letras_temp = Array.new
letrasComic = Array.new
img = MultiArray.load_ubyte "Fontes/ComicSans.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasComic += l }
for i in 0..nletrasComic.length-1
  letrasComic[i] = ocr.preparaLetra nletrasComic[i]
end
letrasReconhecidasComic = Array.new
coeficienteComic = Array.new
for i in 0..letrasComic.length-1
  mi = (letrasComic[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasComic.push hTemp.index(hTemp.values.max)
  coeficienteComic.push hTemp.values.max
end

#Lucida

nletrasLucida = Array.new
letras_temp = Array.new
letrasLucida = Array.new
img = MultiArray.load_ubyte "Fontes/LucidaSans.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasLucida += l }
for i in 0..nletrasLucida.length-1
  letrasLucida[i] = ocr.preparaLetra nletrasLucida[i]
end
letrasReconhecidasLucida = Array.new
coeficienteLucida = Array.new
for i in 0..letrasLucida.length-1
  mi = (letrasLucida[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasLucida.push hTemp.index(hTemp.values.max)
  coeficienteLucida.push hTemp.values.max
end

#Verdana

nletrasVerdana = Array.new
letras_temp = Array.new
letrasVerdana = Array.new
img = MultiArray.load_ubyte "Fontes/Verdana.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasVerdana += l }
for i in 0..nletrasVerdana.length-1
  letrasVerdana[i] = ocr.preparaLetra nletrasVerdana[i]
end
letrasReconhecidasVerdana = Array.new
coeficienteVerdana = Array.new
for i in 0..letrasVerdana.length-1
  mi = (letrasVerdana[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    candidateScore = (value*mi).sum
    temp = value.mask(value > 0)
    if temp.width != 0
      idealWeightModelScore = temp.sum
      recognitionQuotient = candidateScore / idealWeightModelScore.to_f
    else
      recognitionQuotient = 0
    end
    hTemp[key] = recognitionQuotient
  }
  letrasReconhecidasVerdana.push hTemp.index(hTemp.values.max)
  coeficienteVerdana.push hTemp.values.max
end



############################################################################



h = ocr.getLetraAprendida

#TimesNewRoman

nletrasTimes1 = Array.new
letras_temp = Array.new
letrasTimes1 = Array.new
#img = MultiArray.load_ubyte "Fontes/TimesNewRoman.jpg"
img = MultiArray.load_ubyte "Fontes/TimesNewRoman.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTimes1 += l }
for i in 0..nletrasTimes1.length-1
  letrasTimes1[i] = ocr.preparaLetra nletrasTimes1[i]
end
letrasReconhecidasTimes1 = Array.new
coeficienteTimes1 = Array.new
for i in 0..nletrasTimes1.length-1
  entrada = (letrasTimes1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTimes1.push hTemp.index(hTemp.values.max)
  coeficienteTimes1.push hTemp.values.max
end


nletrasTimes2 = Array.new
letras_temp = Array.new
letrasTimes2 = Array.new
img = MultiArray.load_ubyte "Fontes/TimesNewRoman36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTimes2 += l }
for i in 0..nletrasTimes2.length-1
  letrasTimes2[i] = ocr.preparaLetra nletrasTimes2[i]
end
letrasReconhecidasTimes2 = Array.new
coeficienteTimes2 = Array.new
for i in 0..nletrasTimes2.length-1
  letrasTimes2[i] = ocr.preparaLetra nletrasTimes2[i]
  entrada = (letrasTimes2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTimes2.push hTemp.index(hTemp.values.max)
  coeficienteTimes2.push hTemp.values.max
end

nletrasTimes3 = Array.new
letras_temp = Array.new
letrasTimes3 = Array.new
img = MultiArray.load_ubyte "TimesNewRoman24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTimes3 += l }
for i in 0..nletrasTimes3.length-1
  letrasTimes3[i] = ocr.preparaLetra nletrasTimes3[i]
end
letrasReconhecidasTimes3 = Array.new
coeficienteTimes3 = Array.new
for i in 0..nletrasTimes3.length-1
  letrasTimes3[i] = ocr.preparaLetra nletrasTimes3[i]
  entrada = (letrasTimes3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTimes3.push hTemp.index(hTemp.values.max)
  coeficienteTimes3.push hTemp.values.max
end

#Calibri

nletrasCalibri1 = Array.new
letras_temp = Array.new
letrasCalibri1 = Array.new
img = MultiArray.load_ubyte "Fontes/Calibri48.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasCalibri1 += l }
for i in 0..nletrasCalibri1.length-1
  letrasCalibri1[i] = ocr.preparaLetra nletrasCalibri1[i]
end
letrasReconhecidasCalibri1 = Array.new
coeficienteCalibri1 = Array.new
for i in 0..nletrasCalibri1.length-1
  letrasCalibri1[i] = ocr.preparaLetra nletrasCalibri1[i]
  entrada = (letrasCalibri1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasCalibri1.push hTemp.index(hTemp.values.max)
  coeficienteCalibri1.push hTemp.values.max
end

nletrasCalibri2 = Array.new
letras_temp = Array.new
letrasCalibri2 = Array.new
img = MultiArray.load_ubyte "Fontes/Calibri36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasCalibri2 += l }
for i in 0..nletrasCalibri2.length-1
  letrasCalibri2[i] = ocr.preparaLetra nletrasCalibri2[i]
end
letrasReconhecidasCalibri2 = Array.new
coeficienteCalibri2 = Array.new
for i in 0..nletrasCalibri2.length-1
  letrasCalibri2[i] = ocr.preparaLetra nletrasCalibri2[i]
  entrada = (letrasCalibri2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasCalibri2.push hTemp.index(hTemp.values.max)
  coeficienteCalibri2.push hTemp.values.max
end


nletrasCalibri3 = Array.new
letras_temp = Array.new
letrasCalibri3 = Array.new
img = MultiArray.load_ubyte "Calibri24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasCalibri3 += l }
for i in 0..nletrasCalibri3.length-1
  letrasCalibri3[i] = ocr.preparaLetra nletrasCalibri3[i]
end
letrasReconhecidasCalibri3 = Array.new
coeficienteCalibri3 = Array.new
for i in 0..nletrasCalibri3.length-1
  letrasCalibri3[i] = ocr.preparaLetra nletrasCalibri3[i]
  entrada = (letrasCalibri3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasCalibri3.push hTemp.index(hTemp.values.max)
  coeficienteCalibri3.push hTemp.values.max
end

#Tahoma


nletrasTahoma1 = Array.new
letras_temp = Array.new
letrasTahoma1 = Array.new
img = MultiArray.load_ubyte "Fontes/Tahoma48.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTahoma1 += l }
for i in 0..nletrasTahoma1.length-1
  letrasTahoma1[i] = ocr.preparaLetra nletrasTahoma1[i]
end
letrasReconhecidasTahoma1 = Array.new
coeficienteTahoma1 = Array.new
for i in 0..nletrasTahoma1.length-1
  letrasTahoma1[i] = ocr.preparaLetra nletrasTahoma1[i]
  entrada = (letrasTahoma1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTahoma1.push hTemp.index(hTemp.values.max)
  coeficienteTahoma1.push hTemp.values.max
end

nletrasTahoma2 = Array.new
letras_temp = Array.new
letrasTahoma2 = Array.new
img = MultiArray.load_ubyte "Fontes/Tahoma36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTahoma2 += l }
for i in 0..nletrasTahoma2.length-1
  letrasTahoma2[i] = ocr.preparaLetra nletrasTahoma2[i]
end
letrasReconhecidasTahoma2 = Array.new
coeficienteTahoma2 = Array.new
for i in 0..nletrasTahoma2.length-1
  letrasTahoma2[i] = ocr.preparaLetra nletrasTahoma2[i]
  entrada = (letrasTahoma2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTahoma2.push hTemp.index(hTemp.values.max)
  coeficienteTahoma2.push hTemp.values.max
end


nletrasTahoma3 = Array.new
letras_temp = Array.new
letrasTahoma3 = Array.new
img = MultiArray.load_ubyte "Tahoma24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasTahoma3 += l }
for i in 0..nletrasTahoma3.length-1
  letrasTahoma3[i] = ocr.preparaLetra nletrasTahoma3[i]
end
letrasReconhecidasTahoma3 = Array.new
coeficienteTahoma3 = Array.new
for i in 0..nletrasTahoma3.length-1
  letrasTahoma3[i] = ocr.preparaLetra nletrasTahoma3[i]
  entrada = (letrasTahoma3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasTahoma3.push hTemp.index(hTemp.values.max)
  coeficienteTahoma3.push hTemp.values.max
end



#Arial


nletrasArial1 = Array.new
letras_temp = Array.new
letrasArial1 = Array.new
img = MultiArray.load_ubyte "Fontes/Arial48.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasArial1 += l }
for i in 0..nletrasArial1.length-1
  letrasArial1[i] = ocr.preparaLetra nletrasArial1[i]
end
letrasReconhecidasArial1 = Array.new
coeficienteArial1 = Array.new
for i in 0..nletrasArial1.length-1
  letrasArial1[i] = ocr.preparaLetra nletrasArial1[i]
  entrada = (letrasArial1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasArial1.push hTemp.index(hTemp.values.max)
  coeficienteArial1.push hTemp.values.max
end

nletrasArial2 = Array.new
letras_temp = Array.new
letrasArial2 = Array.new
img = MultiArray.load_ubyte "Fontes/Arial36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasArial2 += l }
for i in 0..nletrasArial2.length-1
  letrasArial2[i] = ocr.preparaLetra nletrasArial2[i]
end
letrasReconhecidasArial2 = Array.new
coeficienteArial2 = Array.new
for i in 0..nletrasArial2.length-1
  letrasArial2[i] = ocr.preparaLetra nletrasArial2[i]
  entrada = (letrasArial2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasArial2.push hTemp.index(hTemp.values.max)
  coeficienteArial2.push hTemp.values.max
end


nletrasArial3 = Array.new
letras_temp = Array.new
letrasArial3 = Array.new
img = MultiArray.load_ubyte "Fontes/Arial24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasArial3 += l }
for i in 0..nletrasArial3.length-1
  letrasArial3[i] = ocr.preparaLetra nletrasArial3[i]
end
letrasReconhecidasArial3 = Array.new
coeficienteArial3 = Array.new
for i in 0..nletrasArial3.length-1
  letrasArial3[i] = ocr.preparaLetra nletrasArial3[i]
  entrada = (letrasArial3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasArial3.push hTemp.index(hTemp.values.max)
  coeficienteArial3.push hTemp.values.max
end

#Comic Sans

nletrasComic1 = Array.new
letras_temp = Array.new
letrasComic1 = Array.new
img = MultiArray.load_ubyte "Fontes/ComicSans48.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasComic1 += l }
for i in 0..nletrasComic1.length-1
  letrasComic1[i] = ocr.preparaLetra nletrasComic1[i]
end
letrasReconhecidasComic1 = Array.new
coeficienteComic1 = Array.new
for i in 0..nletrasComic1.length-1
  letrasComic1[i] = ocr.preparaLetra nletrasComic1[i]
  entrada = (letrasComic1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasComic1.push hTemp.index(hTemp.values.max)
  coeficienteComic1.push hTemp.values.max
end


nletrasComic2 = Array.new
letras_temp = Array.new
letrasComic2 = Array.new
img = MultiArray.load_ubyte "Fontes/ComicSans36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasComic2 += l }
for i in 0..nletrasComic2.length-1
  letrasComic2[i] = ocr.preparaLetra nletrasComic2[i]
end
letrasReconhecidasComic2 = Array.new
coeficienteComic2 = Array.new
for i in 0..nletrasComic2.length-1
  letrasComic2[i] = ocr.preparaLetra nletrasComic2[i]
  entrada = (letrasComic2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasComic2.push hTemp.index(hTemp.values.max)
  coeficienteComic2.push hTemp.values.max
end

#Lucida

nletrasLucida1 = Array.new
letras_temp = Array.new
letrasLucida1 = Array.new
img = MultiArray.load_ubyte "Fontes/LucidaSans48.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasLucida1 += l }
for i in 0..nletrasLucida1.length-1
  letrasLucida1[i] = ocr.preparaLetra nletrasLucida1[i]
end
letrasReconhecidasLucida1 = Array.new
coeficienteLucida1 = Array.new
for i in 0..nletrasLucida1.length-1
  letrasLucida1[i] = ocr.preparaLetra nletrasLucida1[i]
  entrada = (letrasLucida1[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasLucida1.push hTemp.index(hTemp.values.max)
  coeficienteLucida1.push hTemp.values.max
end

nletrasLucida2 = Array.new
letras_temp = Array.new
letrasLucida2 = Array.new
img = MultiArray.load_ubyte "Fontes/LucidaSans36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasLucida2 += l }
for i in 0..nletrasLucida2.length-1
  letrasLucida2[i] = ocr.preparaLetra nletrasLucida2[i]
end
letrasReconhecidasLucida2 = Array.new
coeficienteLucida2 = Array.new
for i in 0..nletrasLucida2.length-1
  letrasLucida2[i] = ocr.preparaLetra nletrasLucida2[i]
  entrada = (letrasLucida2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasLucida2.push hTemp.index(hTemp.values.max)
  coeficienteLucida2.push hTemp.values.max
end


nletrasLucida3 = Array.new
letras_temp = Array.new
letrasLucida3 = Array.new
img = MultiArray.load_ubyte "LucidaSans24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasLucida3 += l }
for i in 0..nletrasLucida3.length-1
  letrasLucida3[i] = ocr.preparaLetra nletrasLucida3[i]
end
letrasReconhecidasLucida3 = Array.new
coeficienteLucida3 = Array.new
for i in 0..nletrasLucida3.length-1
  letrasLucida3[i] = ocr.preparaLetra nletrasLucida3[i]
  entrada = (letrasLucida3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasLucida3.push hTemp.index(hTemp.values.max)
  coeficienteLucida3.push hTemp.values.max
end

#Verdana

nletrasVerdana2 = Array.new
letras_temp = Array.new
letrasVerdana2 = Array.new
img = MultiArray.load_ubyte "Fontes/Verdana36.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasVerdana2 += l }
for i in 0..nletrasVerdana2.length-1
  letrasVerdana2[i] = ocr.preparaLetra nletrasVerdana2[i]
end
letrasReconhecidasVerdana2 = Array.new
coeficienteVerdana2 = Array.new
for i in 0..nletrasVerdana2.length-1
  letrasVerdana2[i] = ocr.preparaLetra nletrasVerdana2[i]
  entrada = (letrasVerdana2[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasVerdana2.push hTemp.index(hTemp.values.max)
  coeficienteVerdana2.push hTemp.values.max
end


nletrasVerdana3 = Array.new
letras_temp = Array.new
letrasVerdana3 = Array.new
img = MultiArray.load_ubyte "Verdana24.jpg"
linhas = ocr.encontraLinha img
linhas.each { |l| letras_temp.push ocr.encontraLetra l }
letras_temp.each {|l| nletrasVerdana3 += l }
for i in 0..nletrasVerdana3.length-1
  letrasVerdana3[i] = ocr.preparaLetra nletrasVerdana3[i]
end
letrasReconhecidasVerdana3 = Array.new
coeficienteVerdana3 = Array.new
for i in 0..nletrasVerdana3.length-1
  letrasVerdana3[i] = ocr.preparaLetra nletrasVerdana3[i]
  entrada = (letrasVerdana3[i] <= 128).conditional(1,0)
  hTemp = Hash.new
  h.each {|key,value|
    sabedoria = 0.0
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      if value[i].include? mapeamentoBinario
        sabedoria += 1
      end
    end
    hTemp[key] = sabedoria/entrada.height
    break if hTemp[key] == 1.0
  }
  letrasReconhecidasVerdana3.push hTemp.index(hTemp.values.max)
  coeficienteVerdana3.push hTemp.values.max
end


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

















for i in "A"[0].."Z"[0]
  hash << elemento = XML::Node.new('elemento')
  elemento['caracter'] = i.chr
  elemento << (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
end
for i in "a"[0].."z"[0]
  LetraAprendida[i.chr] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
end
LetraAprendida["À"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill! 
LetraAprendida["Á"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["Â"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["Ã"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["É"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["Ê"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["Í"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["Ó"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["à"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["á"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["â"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ã"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ç"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["é"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ê"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["í"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ó"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ô"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["õ"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!
LetraAprendida["ú"] = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill!



=end