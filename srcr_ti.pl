% SICStus PROLOG: Declaracoes iniciais

:- set_prolog_flag( discontiguous_warnings,off ).
:- set_prolog_flag( single_var_warnings,off ).
:- set_prolog_flag( unknown,fail ).


%Consulta do ficheiro com os dados vindos do excel
:-consult('D:/UM/SRCR_TI/infopross.pl').

%-----------------------------------------------Predicados Auxiliares----------------------------------- - - - - -  -  -  -

%Diz se existe um aresta da paragem A para a paragem B
adjacente(A,B):-
	aresta(A,B,_);
	aresta(B,A,_).

%Indica o numero de ligacoes de uma paragem (a entrar e a sair)
numLigacoes(A,B):-
	findall(A, aresta(A,_,_), L1), length(L1,B).

%Calcula a distancia, em linha reta, entre 2 pontos
distancia(X1, Y1, X2, Y2, Result):-
	P1 is X1 * pi/180,
	P2 is X2 * pi/180,
	Dp is (X2 - X1) * pi/180,
	Dl is (Y2 - Y1) * pi/180,

	A is sin(Dp/2) * sin(Dp/2) * cos(P1) * cos(P2) * sin(Dl/2) * sin(Dl/2),
	C is 2 * atan2(sqrt(A), sqrt(1-A)),

	Result is C * 6371000 * 2.

%Calcular a distância em linha reta entre duas cidades
dist(A, B, D):-
	paragem(A,_,_,X1,Y1,_,_),
	paragem(B,_,_,X2,Y2,_,_),
	distancia(X1,Y1,X2,Y2,D).

%Obtem o elemento à cabeça da lista
cabeca([],-1).
cabeca([X|T],X).

%Inverte uma lista
inverso(Xs, Ys):- inverso(Xs, [], Ys).
inverso([], Xs, Xs).
inverso([X|Xs],Ys, Zs):- inverso(Xs, [X|Ys], Zs).

%Cria uma lista com as saidas de cada paragem
listaSaidas([ID],[(X,ID)]):- numLigacoes(ID,X).
listaSaidas([ID|IDS],[(X,ID)|XS]):- numLigacoes(ID,X),
									listaSaidas(IDS,XS).

%Calcula o maximo de uma lista de pares
maxPares([M],M):- !, true.
maxPares([(X,Id1)|Xs], (M,Id2)):- maxPares(Xs, (M,Id2)), M>=X.
maxPares([(X,Id1)|Xs], (X,Id1)):- maxPares(Xs, (X,Id1)), X> M.

%Retorna os N primeiros elementos de uma lista
take(N, _, Xs) :- N =< 0, !, N =:= 0, Xs = [].  %>
take(_, [], []).
take(N, [X|Xs], [X|Ys]) :- M is N-1, take(M, Xs, Ys).

%Remove da primeira lista os elementos presentes em L2
remove_list([], _, []).
remove_list([X|Tail], L2, Result):- member(X, L2), !, remove_list(Tail, L2, Result). 
remove_list([X|Tail], L2, [X|Result]):- remove_list(Tail, L2, Result).

%Verifica se todos os elementos da segunda lista estão presentes na primeira
verificaCaminho(_,[]).
verificaCaminho([ID|IDS],Ls):-
	paragem(ID,_,L,_,_,_,_),
	remove_list(Ls,L,N),
	verificaCaminho(IDS,N).




%-----------------------------------------------Alineas----------------------------------- - - - - -  -  -  -

%-----------------------------------Q1)------------------------------------------------------
%Calcular um trajeto entre duas paragens.

%---------------Produnfidade
trajetoQ1(Inicio,Fim, C):-
	q1(Inicio,[Fim],C).

q1(Inicio, [Inicio|T], [Inicio|T]).
q1(Inicio, [E|T], Caminho):-
	adjacente(Est, E),
	\+ member(Est, [E|T]),
	q1(Inicio, [Est, E|T], Caminho).

%---------------Largura
trajetoQ1BF(Inicio, Fim, C):-
	q1bf(Inicio,Fim, [[Inicio]],Caminho),
	inverso(Caminho,C).

q1bf(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q1bf(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrla(CaminhoCandidato, N),
	append(T,N, Prox),
	q1bf(Inicio, Fim, Prox, S).

addOrla([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrla(T,[]).


%-----------------------------------Q2)------------------------------------------------------
%	Calcular um trajeto entre duas paragens, usando apenas paragens com uma determinada caracteristica
%( A=1, com Bilheteira, A=2, com Bar e A=3 com Bilheteira e Bar )
%Exemplos   trajetoQ2(14,17,2,C) V         trajetoQ2(14,16,1,C). X
%---------------Produnfidade

trajetoQ2(Inicio,Fim,A, C):-
	(A == 1, q2Bilheteira(Inicio,[Fim],C);
	 A == 2, q2Bar(Inicio,[Fim],C);
	 A == 3, q2BarBil(Inicio,[Fim],C)).

q2Bilheteira(Inicio, [Inicio|T], [Inicio|T]).
q2Bilheteira(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,1.0,_),
	q2Bilheteira(Inicio, [Est, E|T], Caminho).

q2Bar(Inicio, [Inicio|T], [Inicio|T]).
q2Bar(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,_,1.0),
	q2Bar(Inicio, [Est, E|T], Caminho).

q2BarBil(Inicio, [Inicio|T], [Inicio|T]).
q2BarBil(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,1.0,1.0),
	q2BarBil(Inicio, [Est, E|T], Caminho).

%---------------Largura

trajetoQ2BF(Inicio, Fim, A, C):-
	(A == 1, q2bfBilheteira(Inicio,Fim, [[Inicio]],Caminho);
	 A == 2, q2bfBar(Inicio,Fim, [[Inicio]],Caminho);
	 A == 3, q2bfBarBil(Inicio,Fim, [[Inicio]],Caminho)),
	inverso(Caminho,C).

q2bfBilheteira(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q2bfBilheteira(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBilheteira(CaminhoCandidato, N),
	append(T,N, Prox),
	q2bfBilheteira(Inicio, Fim, Prox, S).

addOrlaBilheteira([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,1.0,_),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBilheteira(T,[]).


q2bfBar(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q2bfBar(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBar(CaminhoCandidato, N),
	append(T,N, Prox),
	q2bfBar(Inicio, Fim, Prox, S).

addOrlaBar([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,_,1.0),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBar(T,[]).

q2bfBarBil(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q2bfBarBil(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBarBil(CaminhoCandidato, N),
	append(T,N, Prox),
	q2bf(Inicio, Fim, Prox, S).

addOrlaBarBil([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,1.0,1.0),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBarBil(T,[]).

%-----------------------------------Q3)------------------------------------------------------
%Excluir uma ou mais caracteristicas de paragens para o percurso
%( A=1, sem Bilheteira, A=2, com sem e A=3 sem Bilheteira nem Bar )
%Exemplos    trajetoQ3(3,5,1,A)      (73,77,2,A)

%---------------Profundidade
trajetoQ3(Inicio,Fim,A, C):-
	(A == 1, q3Bilheteira(Inicio,[Fim],C);
	 A == 2, q3Bar(Inicio,[Fim],C);
	 A == 3, q3BarBil(Inicio,[Fim],C)).

q3Bilheteira(Inicio, [Inicio|T], [Inicio|T]).
q3Bilheteira(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,0.0,_),
	q3Bilheteira(Inicio, [Est, E|T], Caminho).

q3Bar(Inicio, [Inicio|T], [Inicio|T]).
q3Bar(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,_,0.0),
	q3Bar(Inicio, [Est, E|T], Caminho).

q3BarBil(Inicio, [Inicio|T], [Inicio|T]).
q3BarBil(Inicio, [E|T], Caminho):-
	adjacente(Est,E),
	\+ member(Est, [E|T]),
	paragem(Est,_,_,_,_,0.0,0.0),
	q3BarBil(Inicio, [Est, E|T], Caminho).

%---------------Largura

trajetoQ3BF(Inicio, Fim, A, C):-
	(A == 1, q3bfBilheteira(Inicio,Fim, [[Inicio]],Caminho);
	 A == 2, q3bfBar(Inicio,Fim, [[Inicio]],Caminho);
	 A == 3, q3bfBarBil(Inicio,Fim, [[Inicio]],Caminho)),
	inverso(Caminho,C).

q3bfBilheteira(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q3bfBilheteira(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBilheteiraQ3(CaminhoCandidato, N),
	append(T,N, Prox),
	q3bfBilheteira(Inicio, Fim, Prox, S).

addOrlaBilheteiraQ3([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,0.0,_),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBilheteiraQ3(T,[]).


q3bfBar(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q3bfBar(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBarQ3(CaminhoCandidato, N),
	append(T,N, Prox),
	q3bfBar(Inicio, Fim, Prox, S).

addOrlaBarQ3([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,_,0.0),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBarQ3(T,[]).

q3bfBarBil(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):- cabeca([Candidato|T], Fim).
q3bfBarBil(Inicio, Fim, [CaminhoCandidato|T], S):-
	addOrlaBarBilQ3(CaminhoCandidato, N),
	append(T,N, Prox),
	q2bf(Inicio, Fim, Prox, S).

addOrlaBarBilQ3([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato), paragem(ProxCandidato,_,_,_,_,0.0,0.0),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaBarBilQ3(T,[]).

%-----------------------------------Q4)------------------------------------------------------
%Identificar quais as linhas com o maior número de possibilidades de saída num determinado
%percurso.





%-----------------------------------Q5)--------------------------------------------------------------
%	Determinar caminho com menos paragens intermedias
%Automático usando Breadth-First

trajetoQ5BF(Inicio, Fim, F):-
	q1bf(Inicio,Fim, [[Inicio]],C),
	inverso(C,F).

%-----------------------------------Q6)--------------------------------------------------------------
%	Escolher o percurso mais rápido (usando o critério da distância)
% Exemplo (3,11,C).

trajetoQ6(A,B, (T,C)):-
	dist(A, B, D),
	aestrela(A, B, [[A]/0/D], S/C/_),
	inverso(S,T).

aestrela(Inicio, Fim, Caminhos, S):-
  obtem_melhor(Caminhos, S),
  S = [Candidato|_]/_/_,
  Candidato == Fim.

aestrela(Inicio, Fim, Caminhos, S):-
  obtem_melhor(Caminhos, O),
  seleciona(O,Caminhos, Outro),
  expande_aestrela(Fim, O, CaminhosAux),
  append(Outro,CaminhosAux, NovosCaminhos),
  aestrela(Inicio, Fim, NovosCaminhos, S).

obtem_melhor([L],L):-!.
obtem_melhor([C1/D1/E1, _/D2/E2|T], S):-
  E1+D1 =< E2+D2,!,  %>
  obtem_melhor([C1/D1/E1|T], S).
obtem_melhor([_|T], S):-
  obtem_melhor(T, S).

seleciona(E, [E|Xs], Xs).
seleciona(E, [X|Xs], [X|Ys]) :- seleciona(E, Xs, Ys).

expande_aestrela(Fim, O, CaminhosAux):-
  findall(N, adjacente6(Fim, O, N), CaminhosAux).

adjacente6(Fim, [Nodo|Caminho]/Custo/_, [ProxNodo,Nodo|Caminho]/NovoCusto/Est) :-
	adjacente_dist(Nodo, ProxNodo, PassoCusto),
  \+ member(ProxNodo, Caminho),
	NovoCusto is Custo + PassoCusto,
	dist(ProxNodo, Fim, Est).

adjacente_dist(Nodo, ProxNodo, D):-
	aresta(Nodo,ProxNodo,D).
adjacente_dist(Nodo, ProxNodo, D):-
	aresta(ProxNodo,Nodo,D).


%-----------------------------------Q7)--------------------------------------------------------------
% Escolher o percurso que passe apenas por uma determinada linha
% Exemplo (7,26,5,C).      (7,11,5,C).

%---------------Profundidade
trajetoQ7(Inicio,Fim, Linha, C):-
		paragem(Inicio,_,L1,_,_,_,_),
		member(Linha, L1),				
		paragem(Fim,_,L2,_,_,_,_),
		member(Linha, L2),		
	q7(Inicio,[Fim],Linha,C).

q7(Inicio, [Inicio|T], Linha, [Inicio|T]):-
		paragem(Inicio,_,L1,_,_,_,_),
		member(Linha, L1).
q7(Inicio, [E|T], Linha, Caminho):-
	adjacente(Est, E),
	\+ member(Est, [E|T]),
	paragem(Est,_,Ls,_,_,_,_),
	member(Linha, Ls),
	q7(Inicio, [Est, E|T], Linha, Caminho).


%---------------Largura
%Não termina caso o Fim esteja numa Linha diferente

trajetoQ7BF(Inicio, Fim, Linha, C):-
	q7bf(Inicio,Fim, [[Inicio]], Linha, Caminho),
		paragem(Inicio,_,L1,_,_,_,_), 
		member(Linha, L1),			
		paragem(Fim,_,L2,_,_,_,_),		
		member(Linha, L2),		
	inverso(Caminho,C).

q7bf(Inicio, Fim, [[Candidato|T]|_], Linha, [Candidato|T]):- 
	cabeca([Candidato|T], Fim).

q7bf(Inicio, Fim, [CaminhoCandidato|T], Linha, S):-
	addOrlaq7(CaminhoCandidato, Linha, N),
	append(T,N, Prox),
	q7bf(Inicio, Fim, Prox, Linha, S).

addOrlaq7([Candidato|T], Linha, NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
			(adjacente(ProxCandidato, Candidato),
				paragem(ProxCandidato,_,L2,_,_,_,_),
				member(Linha, L2),
				\+member(ProxCandidato, [Candidato|T])),
			NovosCandidatos),!.
addOrlaq7(T, Linha, []).


%-----------------------------------Q8)--------------------------------------------------------------
% Escolher uma ou mais linhas por onde o percurso deverá passar, dadas duas estações.
% Exemplo: (9,23,[0],C).

%---------------Profundidade

trajetoQ8(Inicio, Fim, Linhas, C):-
	q1(Inicio,[Fim],C),
	verificaCaminho(C,Linhas).

%---------------Largura

trajetoQ8BF(Inicio, Fim, Linhas, C):-
	q1bf(Inicio,Fim, [[Inicio]],Caminho),
	verificaCaminho(Caminho, Linhas),
	inverso(Caminho,C).


%-----------------------------------Adicional--------------------------------------------------------------
%Determinar as N paragens com mais saidas de um percurso

%---------------Profundidade

trajetoAdicional(Inicio,Fim,V,C):-
	q1(Inicio,[Fim],X),
	listaSaidas(X,A),
	sort(A,B),
	inverso(B,F),
	take(V,F,C).

%---------------Largura

% V é o numero de paragens do top, C é o par (saidas,IdParagem) e A é o caminho
trajetoAdicionalBF(Inicio, Fim, V, T, A):-
	q1bf(Inicio,Fim, [[Inicio]],Caminho),
	listaSaidas(Caminho,P),
	inverso(Caminho,A),
	sort(P,S),
	inverso(S,F),
	take(V,F,T).