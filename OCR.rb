require 'rubygems'
require 'hornetseye_v4l2'
require 'hornetseye_xorg'
require 'hornetseye_rmagick'
require 'nokogiri'
require 'espeak-ruby'
require "rubygame"
include Hornetseye
include ESpeak

class OCR
  #*************************#
  #Constantes               #
  #*************************#

  #Define a largura/altura da matriz de entrada para a rede neural
  DimensaoEntrada = 16
  
  #*************************#
  #Variáveis                #
  #*************************#
  #Variável que referencia o arquivo de letras aprendidas da rede neural sem peso 
  @letraAprendida = nil
  #Variável que armazena a cor que serve de treshold da imagem atual
  @corLimite = nil
  #Hash com as matrizes pesos das letras aprendidas pela rede neural com peso
  LetraAprendida = Hash.new
  
  #*************************#
  #Métodos                  #
  #*************************#
  
  def initialize()
    $KCODE = 'utf-8'
    #Inicia testando se o arquivo XML que armazena os caracteres aprendidos já existe ou precisa ser recriado
    #Se não existe, crio o arquivo XML inicialmente vazio
    if not FileTest.exist? "Fontes/Fontes.xml" or not FileTest.exist? "Fontes/RedeNeural.xml" or not FileTest.exist? "Fontes/RedeNeuralPeso.xml"
      criaXMLFonte()
      criaXMLRedeNeural()
      criaXMLRedeNeuralPeso()
    end
    
    f = File.open('Fontes/Fontes.xml', 'r')
    doc = Nokogiri::XML(f)
    dimensao = doc.xpath('//fontes/@dimensaoEntrada')[0].value.to_i
    f.close
    #Se a dimensão que foi gravada no XML é diferente da dimensão atual, refaço o arquivo XML
    if dimensao != DimensaoEntrada
      criaXMLFonte()
      criaXMLRedeNeural()
      criaXMLRedeNeuralPeso()
    end
    
    treinamento()
  end
#*****************************************************
  
  def criaXMLFonte()
    strXML = "<ocr><fontes dimensaoEntrada='#{DimensaoEntrada}'/></ocr>"
    
    arquivo = File.open('Fontes/Fontes.xml', 'w')
    xml = Nokogiri::XML(strXML)
    arquivo.puts xml.to_xml
    arquivo.close
  end
#*****************************************************

  #Método que cria o arquivo XML que armazena os caracteres aprendidos para a rede neural sem peso
  def criaXMLRedeNeural()
    strXML = "<RedeNeural><caracteres>"
    for i in "A"[0].."Z"[0]
      strXML += "<caracter nome='#{i.chr}'>"
      for i in 0..DimensaoEntrada-1
        strXML += "<linhas_#{i}></linhas_#{i}>"
      end
      strXML +="</caracter>"
    end
    for i in "a"[0].."z"[0]
      strXML += "<caracter nome='#{i.chr}'>"
      for i in 0..DimensaoEntrada-1
        strXML += "<linhas_#{i}></linhas_#{i}>"
      end
      strXML +="</caracter>"
    end
    strXML += "<caracter nome='À'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Á'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Â'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Ã'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='É'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Ê'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Í'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='Ó'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='à'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='á'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='â'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ã'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ç'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='é'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ê'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='í'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ó'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ô'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='õ'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    strXML += "<caracter nome='ú'>"
    for i in 0..DimensaoEntrada-1
      strXML += "<linhas_#{i}></linhas_#{i}>"
    end
    strXML +="</caracter>"
    
    strXML += "</caracteres></RedeNeural>"
    
    arquivo = File.open('Fontes/RedeNeural.xml', 'w')
    xml = Nokogiri::XML(strXML)
    xml.encoding = "utf-8"
    arquivo.puts xml.to_xml
    arquivo.close
  end
#*****************************************************

  #Método que cria o arquivo XML que armazena os caracteres aprendidos para a rede neural com peso
  def criaXMLRedeNeuralPeso()
    pixels = ""
    (DimensaoEntrada*DimensaoEntrada).times { pixels += "0 "}
    
    strXML = "<RedeNeuralPeso><caracteres>"
    
    for i in "A"[0].."Z"[0]
      strXML += "<caracter nome='#{i.chr}'>#{pixels}</caracter>"
    end
    for i in "a"[0].."z"[0]
      strXML += "<caracter nome='#{i.chr}'>#{pixels}</caracter>"
    end
    strXML += "<caracter nome='À'>#{pixels}</caracter>"
    strXML += "<caracter nome='Á'>#{pixels}</caracter>"
    strXML += "<caracter nome='Â'>#{pixels}</caracter>"
    strXML += "<caracter nome='Ã'>#{pixels}</caracter>"
    strXML += "<caracter nome='É'>#{pixels}</caracter>"
    strXML += "<caracter nome='Ê'>#{pixels}</caracter>"
    strXML += "<caracter nome='Í'>#{pixels}</caracter>"
    strXML += "<caracter nome='Ó'>#{pixels}</caracter>"
    strXML += "<caracter nome='à'>#{pixels}</caracter>"
    strXML += "<caracter nome='á'>#{pixels}</caracter>"
    strXML += "<caracter nome='â'>#{pixels}</caracter>"
    strXML += "<caracter nome='ã'>#{pixels}</caracter>"
    strXML += "<caracter nome='ç'>#{pixels}</caracter>"
    strXML += "<caracter nome='é'>#{pixels}</caracter>"
    strXML += "<caracter nome='ê'>#{pixels}</caracter>"
    strXML += "<caracter nome='í'>#{pixels}</caracter>"
    strXML += "<caracter nome='ó'>#{pixels}</caracter>"
    strXML += "<caracter nome='ô'>#{pixels}</caracter>"
    strXML += "<caracter nome='õ'>#{pixels}</caracter>"
    strXML += "<caracter nome='ú'>#{pixels}</caracter>"
    strXML += "</caracteres></RedeNeuralPeso>"
    
    arquivo = File.open('Fontes/RedeNeuralPeso.xml', 'w')
    xml = Nokogiri::XML(strXML)
    xml.encoding = "utf-8"
    arquivo.puts xml.to_xml
    arquivo.close
  end
#*****************************************************

  #Método que faz o treinamento da rede neural
  def treinamento()
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    fontesAprendidas = Array.new
    xmlFontes = xml.xpath('//fontes/fonte')
    xmlFontes.each {|fonte|
      fontesAprendidas.push fonte.content
    }
    #Vai no diretório 'Fontes' e pega todos os arquivos '.jpg' que contém as fontes para servirem de treinamento
    fontes = Dir["Fontes/*.jpg"]
    for i in 0..fontes.length-1
      fonte = fontes[i]
      #Só faço os cálculos caso a fonte ainda não tenha sido aprendida
      if not fontesAprendidas.include? fonte
        #Neste caso é uma fonte nova que terá que ser aprendida
        letras = Array.new
        img = MultiArray.load_ubyte fonte
        #Encontra linha por linha
        linhas = encontraLinha img
        #Para cada linha, encontra as letras
        linhas.each { |l| letras.push encontraLetra(l)[0] }
        letras.flatten!
        
        aprendeLetra(letras, fonte)
      end
    end
    inicializaLetraAprendida()
    inicializaHash()
  end
#*****************************************************

  #Método que coloca em memória o arquivo final de caracteres aprendidos
  def inicializaLetraAprendida()
    arquivo = File.open('Fontes/RedeNeural.xml', 'r')
    @letraAprendida = Nokogiri::XML(arquivo)
    arquivo.close
  end
#*****************************************************

  #Método que somente lê do XML e seta os valores da hash
  def inicializaHash()
    for i in "A"[0].."Z"[0]
      LetraAprendida[i.chr] = getCaracterXMLRedeNeuralPeso(i.chr)
    end
    for i in "a"[0].."z"[0]
      LetraAprendida[i.chr] = getCaracterXMLRedeNeuralPeso(i.chr)
    end
    LetraAprendida["À"] = getCaracterXMLRedeNeuralPeso("À")
    LetraAprendida["Á"] = getCaracterXMLRedeNeuralPeso("Á")
    LetraAprendida["Â"] = getCaracterXMLRedeNeuralPeso("Â")
    LetraAprendida["Ã"] = getCaracterXMLRedeNeuralPeso("Ã")
    LetraAprendida["É"] = getCaracterXMLRedeNeuralPeso("É")
    LetraAprendida["Ê"] = getCaracterXMLRedeNeuralPeso("Ê")
    LetraAprendida["Í"] = getCaracterXMLRedeNeuralPeso("Í")
    LetraAprendida["Ó"] = getCaracterXMLRedeNeuralPeso("Ó")
    LetraAprendida["à"] = getCaracterXMLRedeNeuralPeso("à")
    LetraAprendida["á"] = getCaracterXMLRedeNeuralPeso("á")
    LetraAprendida["â"] = getCaracterXMLRedeNeuralPeso("â")
    LetraAprendida["ã"] = getCaracterXMLRedeNeuralPeso("ã")
    LetraAprendida["ç"] = getCaracterXMLRedeNeuralPeso("ç")
    LetraAprendida["é"] = getCaracterXMLRedeNeuralPeso("é")
    LetraAprendida["ê"] = getCaracterXMLRedeNeuralPeso("ê")
    LetraAprendida["í"] = getCaracterXMLRedeNeuralPeso("í")
    LetraAprendida["ó"] = getCaracterXMLRedeNeuralPeso("ó")
    LetraAprendida["ô"] = getCaracterXMLRedeNeuralPeso("ô")
    LetraAprendida["õ"] = getCaracterXMLRedeNeuralPeso("õ")
    LetraAprendida["ú"] = getCaracterXMLRedeNeuralPeso("ú")
  end
#*****************************************************
  
  #Método que dada uma imagem, calcula um treshold baseado na cor de fundo da imagem
  def encontraCorLimite(img)
    pixels = img.components
    num_pixels = pixels.max
    histograma = pixels.histogram num_pixels+1
    mascara = histograma.between? histograma.max, histograma.max+1
    #Decubro a label dada aos pixels com a cor mais frequente da imagem (provavelmente o fundo do papel)
    #labelPixelMax = Sequence( INT, num_pixels+1 ).indgen.mask(mascara).to_a[0]
    labelPixelMax = lazy( num_pixels+1, 1 ){|i,j| i }[0]
    labelPixelMax = labelPixelMax.mask(mascara).to_a[0]
    mascaraPixelMax = pixels.eq labelPixelMax
    #Cor RGB do pixel mais frequente variando de 0..255
    corLimite = img.mask(mascaraPixelMax)[0]
    #Margem de 15% sobre a cor do fundo, de maneira que pixels com cores abaixo desse valor serão considerados pixels de caracteres
    @corLimite = (corLimite*0.85).round
  end

  #Método que recebe a imagem do papel que contém o texto e retorna uma array com as linhas do texto
  def encontraLinha(img)
    linhas = Array.new
    x = lazy( *img.shape ) { |i,j| i }
    y = lazy( *img.shape ) { |i,j| j }
    encontraCorLimite img
    componentes = (img <= @corLimite).components
    num_componentes = componentes.max
    alturaMedia = 0.0
    intLinha = 0
    numMedioPixel = 0.0
    nComponente = 1
    
    #Faço um histograma para saber quantos pixels cada componente conexo tem
    histograma = componentes.histogram num_componentes+1
    
    #A partir do histograma, calculo uma media de pixels
    for i in 1..histograma.width-1
      numMedioPixel += histograma[i]
    end
    numMedioPixel = numMedioPixel/histograma.width-1
    
    #Descarto componentes que são muito pequenos (possivelmente lixo), menores que 5% de um caracter
    mascara = histograma.between? 0, (numMedioPixel*0.05).round
    
    #Sequencia de componentes que sao lixos e serão descartados
    #componenteLixo = Sequence( INT, num_componentes+1 ).indgen.mask(mascara).to_a
    componenteLixo = lazy( num_componentes+1, 1 ) {|i,j| i}[0]
    componenteLixo = componenteLixo.mask(mascara).to_a
    
    if componenteLixo.length != 0
      #Coloco a label de todos esses componentes como "zero", para mais a frente ser descartado junto com o fundo do papel
      componenteLixo.each do |c|
        componente = componentes.eq c
        img[x.mask(componente).range, y.mask(componente).range] = 255
      end
      
      #Aqui obtenho novamente os componentes, desta vez já limpo de lixos e ruídos
      componentes = (img <= @corLimite).components
      num_componentes = componentes.max
    end
    
    while nComponente < num_componentes + 1
      caracter = componentes.eq nComponente
      linhaTopo = y.mask( caracter ).range.min
      linhaPe = y.mask( caracter ).range.max + 1
    
      while componentes[0..componentes.width-1, linhaPe..linhaPe].max != 0
        linhaPe += 1
      end
      linha = componentes[0..componentes.width-1, linhaTopo..(linhaPe-1)]
      nComponente = linha.max + 1
      
      alturaMedia += linhaPe - linhaTopo
      intLinha += 1
    end
    alturaMedia = alturaMedia/intLinha
    
    nComponente = 1
    
    while nComponente < num_componentes + 1 
      linha = nil
      linhaTopo, linhaPe = nil,nil
      blnEncontreiLinha = false
      
      while blnEncontreiLinha == false and nComponente < num_componentes + 1 
        caracter = componentes.eq nComponente
        
        if linhaTopo.nil?
          linhaTopo = y.mask( caracter ).range.min
          while componentes[0..componentes.width-1, linhaTopo..linhaTopo].max != 0 and linhaTopo != 0
            linhaTopo -= 1
          end
          linhaTopo += 1
        end
        
        linhaPe = y.mask( caracter ).range.max + 1
      
        while componentes[0..componentes.width-1, linhaPe..linhaPe].max != 0
          linhaPe += 1
        end
        linha = componentes[0..componentes.width-1, linhaTopo..(linhaPe-1)]
        nComponente = linha.max + 1
        
        alturaCaracter = linhaPe - linhaTopo 
        
        if alturaCaracter > alturaMedia * 0.5
          blnEncontreiLinha = true
        end
      end
      linhas.push img[0..componentes.width-1, linhaTopo..(linhaPe-1)]
    end
    linhas
  end
#*****************************************************
 
  #Método que recebe uma linha do texto e retorna uma array com as letras
  def encontraLetra(linha)
    #Coloco a linha na vertical, dessa forma a ordem dos componentes coincide com a ordem das letras
    letrasEncontradas = Array.new
    espacamentoLetras = Array.new
    linha = linha.to_magick.rotate(90).to_ubyte
    x = lazy( *linha.shape ) { |i,j| i }
    y = lazy( *linha.shape ) { |i,j| j }
    componentes = (linha <= @corLimite).components
    labelLetraAnterior = nil
    espacoMedio = 0.0
    
    for nComponente in 1..componentes.range.max
      letra = componentes.eq nComponente
      alturaLetra = x.mask(letra).range
      larguraLetra = y.mask(letra).range
      componenteMaximo = componentes[0..letra.width-1, larguraLetra].max
      #Se existe um outro componente na faixa da largura da letra em questão, então mescla
      if(componenteMaximo != nComponente)
        componentes[0..letra.width-1, larguraLetra] += letra[0..letra.width-1, larguraLetra].conditional(componenteMaximo - nComponente,0)
      else
        box = [ alturaLetra, larguraLetra ]
        letrasEncontradas.push preparaLetra(linha[*box].to_magick.rotate(-90).to_ubyte)
        
        #Calcula o espaçamento entre uma letra e outra 
        if not labelLetraAnterior.nil?
          letraAnterior = componentes.eq labelLetraAnterior
          posLetraAnterior = y.mask(letraAnterior).range.max
          espacamentoLetras.push(larguraLetra.min - posLetraAnterior)
        end
        labelLetraAnterior = nComponente
      end
    end
    
    totalEspaco = 0
    espacamentoLetras.each{ |esp| totalEspaco += esp}
    espacoMedio = totalEspaco.to_f / espacamentoLetras.length
    
    #Se o espaçamento entre as letras for muito maior que o espaço médio, considero como sendo um espaço entre letras
    espacamentoLetras.map!{ |esp| esp > espacoMedio * 1.5 ? esp = " " : esp = nil}
    espacamentoLetras << " "
    
    return letrasEncontradas, espacamentoLetras
  end
#*****************************************************

  #Método que recebe uma letra e redimensiona para que a letra se ajuste ao tamanho da entrada para a rede neural
  def preparaLetra(letra)
    #Define o fator para não distorcer a letra 
    fatorEscala = letra.width > letra.height ? DimensaoEntrada.to_f/letra.width : DimensaoEntrada.to_f/letra.height
    letra = letra.to_magick
    letra = letra.scale(fatorEscala)
    letra = letra.to_ubyte
    
    letra = (letra < @corLimite).conditional(0,255)
    
    #Verificando se a letra está bem ajustada, sem colunas em branco à esquerda
    #blnLetraOk = false
    #primeiraColuna = (MultiArray.ubyte 1, letra.height).fill! 255
    #y = lazy( *primeiraColuna.shape ) { |i,j| j }
    #intervaloPrimeiraColuna = [ 0, y.mask( primeiraColuna ).range ]
    
    #while blnLetraOk == false
      #mascara = (letra[*intervaloPrimeiraColuna] < 255)
      #indicePixel = Sequence( INT, letra.height ).indgen.mask(mascara).to_a
      
      #if (indicePixel.length == 1) or (indicePixel.length == 2 and indicePixel[1] - indicePixel[0] > 1) or (indicePixel.length == 4 and indicePixel[0] == 0 and indicePixel[1] == 1 and indicePixel[2] == letra.height-2 and indicePixel[3] == letra.height-1)
        #letra = letra[1..letra.width-1,0..letra.height-1]
      #else
        #blnLetraOk = true
      #end
    #end
    resultado = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill! 255
    resultado[0..letra.width-1, 0..letra.height-1] = letra
    resultado
  end
 
#*****************************************************
  
  #Método que dado o caracter, vai no XML e busca os valores armazenados de sua matriz com os pesos aprendidos
  def getCaracterXMLRedeNeuralPeso(caracter)
    arquivo = File.open('Fontes/RedeNeuralPeso.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    
    caracter = xml.xpath("//caracteres/caracter[@nome = '#{caracter}']")[0].content.split(/ /)
    k = -1
    
    matrizCaracter = (MultiArray.int DimensaoEntrada, DimensaoEntrada).fill!
    for i in 0..matrizCaracter.width-1
      for j in 0..matrizCaracter.height-1
        matrizCaracter[i][j] = caracter[k+= 1].to_i
      end
    end
    matrizCaracter
  end
#*****************************************************
  
  #Método que dada a matriz do caracter, passa os valores dos dos elementos para uma string e salva no arquivo XML
  def saveCaracterXMLRedeNeural(caracter, matrizCaracter)
    matrizBinaria = ( matrizCaracter <= @corLimite).conditional(1,0)
    
    arquivo = File.open('Fontes/RedeNeural.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    
    for i in 0..matrizBinaria.height-1
      linha = matrizBinaria[0..matrizBinaria.width-1, i]
      mapeamentoBinario = linha.to_a.join
      consulta = xml.xpath("//caracteres/caracter[@nome = '#{caracter}']/linhas_#{i}/linha[. = '#{mapeamentoBinario}']")
      #Se não existe, adiciona à base de conhecimento
      if consulta.length == 0
        linhasNode = xml.xpath("//caracteres/caracter[@nome = '#{caracter}']/linhas_#{i}")
        linhaXML = Nokogiri::XML::Node.new "linha", xml
        linhaXML.content = mapeamentoBinario
        linhasNode[0].add_child linhaXML
      end
    end
    
    arquivo = File.open('Fontes/RedeNeural.xml', 'w')
    arquivo.puts xml.to_xml
    arquivo.close
  end
  
#*****************************************************
  
  #Método que dada a matriz do caracter, passa os valores dos dos elementos para uma string e salva no arquivo XML
  def saveCaracterXMLRedeNeuralPeso(caracter, matrizCaracter)
    #Imagem binária: 0 fundo, 1 letra
    matrizBinaria = ( matrizCaracter <= @corLimite).conditional(1,0)
    #Letra pontuada: -1 fundo, 1 letra
    matrizPeso = (matrizBinaria < 1).conditional(-1,1)
    matrizPeso = matrizPeso + getCaracterXMLRedeNeuralPeso(caracter)
    strPixelPeso = ""
    matrizPeso.each {|pixel| strPixelPeso += pixel.to_s + " "}
    
    arquivo = File.open('Fontes/RedeNeuralPeso.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    
    caracter = xml.xpath("//caracteres/caracter[@nome = '#{caracter}']")
    caracter[0].content = strPixelPeso
    
    arquivo = File.open('Fontes/RedeNeuralPeso.xml', 'w')
    arquivo.puts xml.to_xml
    arquivo.close
  end
#*****************************************************

  #Método que recebe os caracteres e os salva no arquivo XML
  def aprendeLetra(letras, fonte)
    #Adiciono a nova fonte a ser aprendida no XML
    arquivo = File.open('Fontes/Fontes.xml', 'r')
    xml = Nokogiri::XML(arquivo)
    arquivo.close
    fontesNode = xml.xpath('//fontes')
    fonteXML = Nokogiri::XML::Node.new "fonte", xml
    fonteXML.content = fonte
    fontesNode[0].add_child fonteXML
    arquivo = File.open('Fontes/Fontes.xml', 'w')
    arquivo.puts xml.to_xml
    arquivo.close
    
    letras.reverse!
    
    for i in "A"[0].."Z"[0]
      letra = letras.pop
      saveCaracterXMLRedeNeural( i.chr, letra)
      saveCaracterXMLRedeNeuralPeso( i.chr, letra)
    end
    for i in "a"[0].."z"[0]
      letra = letras.pop
      saveCaracterXMLRedeNeural( i.chr, letra)
      saveCaracterXMLRedeNeuralPeso( i.chr, letra)
    end
    letra = letras.pop
    saveCaracterXMLRedeNeural( "À", letra)
    saveCaracterXMLRedeNeuralPeso( "À", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Á", letra)
    saveCaracterXMLRedeNeuralPeso( "Á", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Â", letra)
    saveCaracterXMLRedeNeuralPeso( "Â", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Ã", letra)
    saveCaracterXMLRedeNeuralPeso( "Ã", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "É", letra)
    saveCaracterXMLRedeNeuralPeso( "É", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Ê", letra)
    saveCaracterXMLRedeNeuralPeso( "Ê", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Í", letra)
    saveCaracterXMLRedeNeuralPeso( "Í", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "Ó", letra)
    saveCaracterXMLRedeNeuralPeso( "Ó", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "à", letra)
    saveCaracterXMLRedeNeuralPeso( "à", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "á", letra)
    saveCaracterXMLRedeNeuralPeso( "á", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "â", letra)
    saveCaracterXMLRedeNeuralPeso( "â", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ã", letra)
    saveCaracterXMLRedeNeuralPeso( "ã", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ç", letra)
    saveCaracterXMLRedeNeuralPeso( "ç", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "é", letra)
    saveCaracterXMLRedeNeuralPeso( "é", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ê", letra)
    saveCaracterXMLRedeNeuralPeso( "ê", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "í", letra)
    saveCaracterXMLRedeNeuralPeso( "í", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ó", letra)
    saveCaracterXMLRedeNeuralPeso( "ó", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ô", letra)
    saveCaracterXMLRedeNeuralPeso( "ô", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "õ", letra)
    saveCaracterXMLRedeNeuralPeso( "õ", letra)
    letra = letras.pop
    saveCaracterXMLRedeNeural( "ú", letra)
    saveCaracterXMLRedeNeuralPeso( "ú", letra)
  end
 
#*****************************************************

  #Método que, dado o caracter, tenta reconhece-lo
  def reconheceRedeNeural(entrada)
    entrada = (entrada <= @corLimite).conditional(1,0)
    letrasPossiveis = Array.new
    DimensaoEntrada.times {letrasPossiveis.push []}
    
    for i in 0..entrada.height-1
      linha = entrada[0..entrada.width-1, i]
      mapeamentoBinario = linha.to_a.join
      consulta = @letraAprendida.xpath("//caracteres/caracter[linhas_#{i}/linha[. = '#{mapeamentoBinario}']]/@nome")
      consulta.each {|e| letrasPossiveis[i].push e.content}
    end
    letrasPossiveis.flatten!
    letrasCandidatas = letrasPossiveis.uniq
    frequencia = []
    resultado = []
    letrasCandidatas.each {|e| frequencia.push letrasPossiveis.count(e)}
    
    if frequencia.length != 0
      maximo = frequencia.max
      begin
        indice = frequencia.index(maximo)
        resultado.push letrasCandidatas.delete_at indice
        frequencia.delete_at indice
      end while maximo == frequencia.max
      coeficienteReconhecimento = (letrasPossiveis.count resultado[0])/DimensaoEntrada.to_f
    else
      resultado = "nil"
      coeficienteReconhecimento = 0.0
    end
    
    return resultado, coeficienteReconhecimento
  end

#*****************************************************

  def reconheceRedeNeuralPeso(entrada, letrasPreReconhecidas=nil)
    mi = (entrada <= @corLimite).conditional(1,0)
    hTemp = Hash.new
    if letrasPreReconhecidas.nil?
      #Caso em que não temos a mínima noção de que letra seja, então testamos todas as letras aprendidas (lento!)
      LetraAprendida.each {|key,value|
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
    else
      #Neste caso, já obtivemos algumas letras possiveis atraves da rede neural sem peso e portanto só precisamos testa-las na rede com peso para definir
      letrasPreReconhecidas.each { |letra|
        candidateScore = (LetraAprendida[letra]*mi).sum
        temp = LetraAprendida[letra].mask(LetraAprendida[letra] > 0)
        if temp.width != 0
          idealWeightModelScore = temp.sum
          recognitionQuotient = candidateScore / idealWeightModelScore.to_f
        else
          recognitionQuotient = 0
        end
        hTemp[letra] = recognitionQuotient
      }
    end
    return hTemp.index(hTemp.values.max), hTemp.values.max  
  end
#*****************************************************

  #Método que após aprendizado, é chamado para identificar o texto
  def le(img)
    letras = Array.new
    espacos = Array.new
    letrasReconhecidas = Array.new
    #Encontra linha por linha
    linhas = encontraLinha img
    #Para cada linha, encontra as letras
    linhas.each { |l|
      letrasTemp, espacosTemp = encontraLetra l 
      letras.push letrasTemp
      espacos.push espacosTemp
    }
    letras.flatten!
    espacos.flatten!
    
    for i in 0..letras.length-1
      letrasObtidas, coeficienteReconhecimento = reconheceRedeNeural letras[i]
      if coeficienteReconhecimento < 0.75
        letrasObtidas = reconheceRedeNeuralPeso letras[i]
      elsif letrasObtidas.length > 1
        letrasObtidas = reconheceRedeNeuralPeso( letras[i], letrasObtidas)
      end
      letrasReconhecidas <<  letrasObtidas[0]
      letrasReconhecidas <<  espacos[i] if not espacos[i].nil?
    end
    espeak("TextoReconhecido.mp3", :text => letrasReconhecidas.to_s, :voice => 'pt', :pitch => 99, :speed => 120)
    Rubygame::Music.load("TextoReconhecido.mp3").play
    return letrasReconhecidas.to_s, Rubygame::Music.load("TextoReconhecido.mp3") 
  end
end