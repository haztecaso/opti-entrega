% Trabajo de Adrián Lattes Grassi, Eva Sánchez Salido y Víctor Vela Cuena
clear all;

% Ejemplo del enunciado de la entrega
c = [5 -3 2 -3 -1 -1 -3 1];
c = -c;
Aeq = [1 -5 -3 8 7 0 0 0];
beq = [2];
A = [ 0  3  0 -1 -6  0  0  0 ;...
      1  0  4  0 -3  1  2 -5 ;...
      0 -4 -7  5 -1 -2 -4  3 ];
b = [ 1 4 -3];
lb = [ 0 0 0 0 0 -15 3 -10];
ub = [ 1 1 1 1 1 inf 17 -1];
J = [1:7];
J0 = [1:5];

E = problema(c,A,b,Aeq,beq,lb,ub,J,J0,"E");

% Ejercicio de nuestra entrega
c = [3  8 -5  2  0  7 -9  5  1];
A = [-1     6    -2    -3     3     0     0     0     0;
    -2    -7    -9    -5     8     0     0     0     0;
    10     0    -7     0    10     6    10     9    -6];

b = [1 -6  1];

Aeq =[ 4    -1    -4    -5     5     0     0     0     0];

beq = [-6];
lb = [0   0   0   0   0  -1 -14  -5 -12];
ub = [1   1   1   1   1  10 -12  -2  -9];
 
J = [1:8];
J0 = [1:5];
P = problema(c,A,b,Aeq,beq,lb,ub,J,J0,"P");

disp("¿Que ejemplo quieres resolver?")
n = input("Pulsa 1 para resolver el problema del enunciado de la entrega y 2 para el problema de nuestra entrega (luego pulsa Enter): ")
if n == 1
    E.resolver()
elseif n ==2
    P.resolver();
end


