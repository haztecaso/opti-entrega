classdef problema < handle
	% Clase que implementa un problema de programación lineal mixta.
	% Se asume que el problema es de minimización.
    % Cosas por mejorar:
    % - Que se puedan pasar opciones a la función linprog.
    % - Compatibilidad con Octave.
    % - Cambiar tabs por espacios (o viceversa).
    % - Comprobaciones de dimensión en el constructor.
    %
    % Trabajo de Adrián Lattes, Eva Sánchez y Víctor Vela
	properties
		c       	% Vector de costes
		A       	% Matriz de coeficientes de restricciones de tipo <=.
		b	        % Matriz de cotas de restricciones de tipo <=.
		Aeq     	% Matriz de coeficientes de restricciones de tipo =.
		beq	        % Matriz de cotas de restricciones de tipo =.
		lb      	% Cotas inferiores de las variables.
		ub      	% Cotas superiores de las variables.
		J	        % Lista de indices de las variables enteras. Se asume que las variables enteras son las primeras.
		J0      	% Lista de indices de las variables binarias. Se asume que las variables binarias son las primeras.
		tag         % Nombre del problema.
		zbar    	% Valor objetivo del problema.
		xbar	    % Solución del problema.
        exitflag	% 1: solución óptima, -2: infactible, -3: no acotado. (ver doc linprog para más detalles).
        ciclados    % Ciclados obtenidos mediante la clase degp
	end
	methods
		function obj = problema(c,A,b,Aeq,beq,lb,ub,J,J0,tag)
			% Constructor de la clase. Pendiente: hacer chequeos de dimensiones.
			obj.c = c;
			obj.A = A;
			obj.b = b;
			obj.Aeq = Aeq;
			obj.beq = beq;
			obj.lb = lb;
			obj.ub = ub;
			obj.ciclados = {};
			if ismember(J0,J)
				obj.J = J;
				obj.J0 = J0;
			else
				error("J0 debe estar incluido en J")
			end
			obj.tag = tag;
		end
		function disp(obj)
			% Función que hace display del problema.
			disp(strcat("Problema ",obj.tag))
            s = "c = "+num2str(obj.c);
			disp(s)
            disp("Restricciones")
			for i = 1:size(obj.A,1)
				s = strcat(num2str(obj.A(i,:))," <= ",num2str(obj.b(i)));
				disp(s)
			end
			for i = 1:size(obj.Aeq,1)
				s = strcat(num2str(obj.Aeq(i,:)),"  = ",num2str(obj.beq(i)));
				disp(s)
			end
            disp("Variables")
			for i = 1:length(obj.c)
				li = num2str(obj.lb(i));
				ui = num2str(obj.ub(i));
				xi = strcat("x",num2str(i));
				s = strcat(li," <= ",xi," <= ",ui);
				if ismember(i,obj.J)
					s = strcat(s," y xi entera");
				end
				disp(s)
			end
		end
        function degpejec(obj)
            % Calcula los ciclados usando la clase degp
            D = degp(obj);
            D.ejec();
            obj.ciclados = D.ciclados;
            disp("Se han encontrado los siguientes ciclados mediante el algoritmo DEGP")
            disp(D);
        end
        function resolver(obj)
            % Calcula una solución usando la clase ramifcorte
            disp(strcat("Resolviendo el problema ",obj.tag))
            disp(obj)
            if isempty(obj.ciclados);
                obj.degpejec();
            end
            RC = ramifcorte(obj,obj.ciclados);
            RC.ejec();
        end
        function s = sol2str(obj)
            if obj.exitflag ==1
                s = strcat("x=[",num2str(obj.xbar'),"], z=",num2str(obj.zbar));
            else
                s = strcat("exitflag =",num2str(exitflag));
            end
        end
        function resolverRelajado(obj)
            % Resuelve el problema lineal relajado.
            options = optimoptions('linprog','Display','none');
            [x,z,exitflag] =  linprog(obj.c,obj.A,obj.b,obj.Aeq,obj.beq,...
                                obj.lb,obj.ub,options);
            % Se redondea para evitar problemas con los errores de máquina.
            obj.xbar = round(x,10);
            obj.zbar = z;
            obj.exitflag = exitflag;
        end
	end
end
