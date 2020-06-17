classdef degp < handle
	% Clase que implementa el algoritmo DEGP para un problema de programación lineal mixta.
    % Mejoras pendientes:
    %   - Vectorizar bucles.   
    %   - Refactorizar bucle principal y subdividir en varias funciones.
    %
    % Trabajo de Adrián Lattes, Eva Sánchez y Víctor Vela
	properties
        P   % Problema a resovler, objeto de clase problema
        ciclados % Lista (tipo cell) de ciclados calculados por el algoritmo
	end
	methods
		function obj = degp(P)
			% Constructor de la clase.
			obj.P = P;
            obj.ciclados = {};
		end
		function disp(obj)
            for i = 1:length(obj.ciclados)
                ciclado = obj.ciclados{i};
                coefs = num2str(ciclado{1});
                cota  = num2str(ciclado{2});
                restr = num2str(ciclado{3});
                i2str = num2str(i);
                s = strcat(i2str,": ",coefs," <= ", cota, " (viene de la restricción ",restr,")");
                disp(s);
            end
		end
        function ejec(obj)
            % Implementación del algoritmo
            A = [obj.P.A; obj.P.Aeq; -obj.P.Aeq];
            b = [obj.P.b obj.P.beq -obj.P.beq];
            for i = 1:size(A,1)
                restr = A(i,:);
                nzeros = size(A,2) - length(obj.P.J0);
                % Se compruebasi la restricción tiene solo variables binarias.
                if [restr(obj.P.J0) zeros(1,nzeros)] == restr
                    a = restr(obj.P.J0);
                    cambio1 = a<0;
                    % Primer cambio de variable
                    a = abs(a);
                    b0 = b(i) + sum(a(cambio1));
                    a(a > b0)=0;
                    % Segundo cambio de variable
                    [a,I] = sort(a);
                    if a(end-1)+a(end) <= b0
                        continue
                    else
                        %Paso 1
                        n0 = length(a);
                        tmp = ones(1,n0)*inf;
                        % Pendiente: refactorizar este bucle en expresiones matriciales
                        for j = 1:n0-1
                            if a(j)+a(end)>b0
                                tmp(j) = a(j)+a(end);
                            end
                        end
                        [tmp,j1] = min(tmp);
                        %Bucle para los pasos 2 y 3
                        while true
                            %Paso 2
                            tmp = ones(1,n0)*inf;
                            % Pendiente: refactorizar este bucle en expresiones matriciales.
                            for j = (j1+1):n0
                                if a(j1)+a(j)>b0
                                    tmp(j) = a(j1)+a(j);
                                end
                            end
                            [tmp,j2] = min(tmp);
                            % Deshacemos el segundo cambio de variables.
                            indicesciclado = I([j1 j2:n0]);
                            ciclado = zeros(1,size(A,2));
                            ciclado(indicesciclado) = 1;
                            bciclado = 1;
                            % Pendiente: refactorizar este bucle en expresiones matriciales.
                            % Este bucle deshace el primer cambio de variables.
                            for k = 1:size(A,2)
                                if ismember(k,find(cambio1))
                                    ciclado(k) = -1*ciclado(k);
                                    if ciclado(k)~=0
                                        bciclado = bciclado -1;
                                    end
                                end
                            end
                            % Pendiente: ajustar índices de las restricciones
                            ciclado = {ciclado,bciclado,i};
                            obj.ciclados{end+1} = ciclado;
                            %Paso 3
                            if j2==j1+1
                                break
                            else
                                j1 = j1+1;
                            end
                        end
                    end
                end
            end
        end
	end
end
