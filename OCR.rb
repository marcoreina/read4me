require 'rubygems'
require 'hornetseye_v4l2'
require 'hornetseye_xorg'
require 'hornetseye_rmagick'
include Hornetseye

class OCR
  #*************************#
  #Constantes               #
  #*************************#

  #Define a largura/altura da matriz de entrada para a rede neural
  DimensaoEntrada = 64.0
  CorLimite = 128
  
  #*************************#
  #Métodos                  #
  #*************************#
  
  def initialize()
    #treinamento()
  end
#*****************************************************  
  
  #Método que faz o treinamento da rede neural
  def treinamento()
    #Vai no diretório 'Fontes' e pega todos os arquivos '.jpg' que contém as fontes para servirem de treinamento
    fontes = Dir["#{'Fontes'}/*.jpg"]
    for i in 0..fontes.length-1
      letras = Array.new
      letras_temp = Array.new
      img = MultiArray.load_ubyte fontes[i]
      #Encontra linha por linha
      linhas = encontraLinha img
      #Para cada linha, encontra as letras
      linhas.each { |l| letras_temp.push encontraLetra l }
      letras_temp.each {|l| letras += l }
      for i in 0..letras.length-1
        letras[i] = preparaLetra letras[i]
      end
      #Aqui entra o método que atualiza a hash das letras!!!
    end
  end
#*****************************************************

  #Método que recebe a imagem do papel que contém o texto e retorna uma array com as linhas do texto
  def encontraLinha(img)
    linhas = Array.new
    nComponente = 0
    y = lazy( *img.shape ) { |i,j| j }
    componentes = (img <= CorLimite).components
    
    while nComponente != componentes.range.max
      linhaTopo, linhaPe = nil,nil
      
      begin 
        nComponente += 1
        caracter = componentes.eq nComponente
        topo = y.mask( caracter ).range.min
        pe = y.mask( caracter ).range.max
        linhaTopo = topo if linhaTopo.nil? or topo < linhaTopo 
        linhaPe = pe if linhaPe.nil? or pe > linhaPe
        linha = componentes[0..componentes.width-1, linhaTopo..linhaPe]
      end while nComponente != linha.max
      linhas.push img[0..componentes.width-1, linhaTopo..linhaPe]
    end
    linhas
  end
#*****************************************************
 
  #Método que recebe uma linha do texto e retorna uma array com as letras
  def encontraLetra(linha)
    #Coloco a linha na vertical, dessa forma a ordem dos componentes coincide com a ordem das letras
    letrasEncontradas = Array.new
    linha = linha.to_magick.rotate(90).to_ubyte
    x = lazy( *linha.shape ) { |i,j| i }
    y = lazy( *linha.shape ) { |i,j| j }
    componentes = (linha <= CorLimite).components
    
    #Esse primeiro loop coloca acentos como mesmo componentes da letra a que pertencem
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
        letrasEncontradas.push linha[*box].to_magick.rotate(-90).to_ubyte
      end
    end
    letrasEncontradas
  end
#*****************************************************

  #Método que recebe uma letra e redimensiona para que a letra se ajuste ao tamanho da entrada para a rede neural
  def preparaLetra(letra)
    #Define o fator para não distorcer a letra 
    fatorEscala = letra.width > letra.height ? DimensaoEntrada/letra.width : DimensaoEntrada/letra.height
    letra = letra.to_magick
    letra = letra.scale(fatorEscala)
    letra = letra.to_ubyte
    #Limpeza de ruído
    letra = (letra <= CorLimite).conditional(0,255)
    molde = (MultiArray.ubyte DimensaoEntrada, DimensaoEntrada).fill! 255
    molde[0..letra.width-1, 0..letra.height-1] = letra
    molde
  end
end