classdef ramifcorte < handle
	% Clase que implementa el algoritmo de ramificación y corte para un problema de programación lineal mixta.
    % Estas son algunas cosas que se nos ocurren que podrían ser mejoradas:
    %   - Vectorizar bucles.
    %   - Hacer compatible con Octave.
    %   - Optimizar cuentas.
    %   - Refactorizar el código para que esté más claro y ordenado.
    %       - Mejorar la interfaz de esta clase para que sea más versátil y fácil de configurar.
    %       - Pasar variable de opciones al constructor para inicializar las propiedades v e inter.
    %   - Mejorar la documentación y los comentarios.
    %
    % Trabajo de Adrián Lattes, Eva Sánchez y Víctor Vela
    
	properties
        P               % Problema a resolver, objeto de clase problema.
        S               % Subproblema actual
        hiperplanos     % Lista (tipo cell) de ciclados calculados por el algoritmo.
        lista           % Lista de problemas del algoritmo.
        zstar           % z* del algoritmo.
        xstar           % x* del algoritmo.
        ramif           % Vector de índices de las variables por las que se ha ramificado.
        exitflag        % 1: solución óptima, -2: infactible.
        iter            % Contador de iteraciones.
        inter           % Si true pide confirmación antes de entrar en la siguiente iteración.
        v               % Si true hace displays dando información de los pasos del algoritmo. Si esta propiedad tiene el variable false se ignorará el valor de la propiedad inter.
        stop            % true si  
	end
	methods
		function obj = ramifcorte(P, hiperplanos)
			% Constructor de la clase.
			obj.P           = P;
            obj.hiperplanos = hiperplanos;
            obj.inter       = true;
            obj.v           = true;
            obj.iter        = 0;
            obj.ramif       = [];
            obj.stop        = false;
		end
        function ejec(obj)
            % Implementación del algoritmo
            % Paso 1
            obj.paso1();
            %Bucle principal del algoritmo
            while true
                obj.iter = obj.iter + 1;
                obj.info("------------")
                obj.info(strcat("Iteración ",num2str(obj.iter)))
                obj.info("------------")
                % Paso 2
                obj.paso2()
                if obj.stop
                    break
                end
                % Paso 3
                obj.paso3()
                obj.info(obj.lista2str())
                if obj.stop
                    break
                end
                % Bucle para los pasos 4 y 5
                i = 0;
                cambio = false;
                while true
                    % Paso 4
                    obj.info(strcat("Paso 4: se resuelve el problema ",obj.S.tag));
                    if isempty(obj.S.exitflag) | cambio
                        obj.S.resolverRelajado();
                        if obj.S.exitflag ~= 1
                            obj.info(strcat("Paso 4: no se ha encontrado una solución óptima. exitflag = ",num2str(obj.S.exitflag)));
                            break
                        end
                    end
                        obj.info(strcat("Paso 4: ",obj.S.sol2str()))
                        % Paso 5
                        cambio = obj.paso5();
                        if ~cambio
                            break
                        end
                    i = i+1;
                    if i> 10
                        disp("ALGO NO VA BIEN: Bucle entre el paso 4 y el 5.")
                        break
                    end
                end
                % Paso 6
                if obj.paso6()
                    input("Pulsa enter para continuar -> Siguiente iteración");
                    continue
                end
                obj.paso7()
                obj.info(obj.lista2str())

            if obj.confirmar();
                input("Pulsa enter para continuar -> Siguiente iteración");
            end
            end
        end
        function paso1(obj)
            % Implementación del paso 1
            s = strcat("Paso 1: se inicializa la lista incluyendo el problema ", obj.P.tag);
            obj.info(s);
            obj.info("Paso 1: z* = inf")
            obj.lista = {obj.P};
            obj.zstar = inf;
        end
        function paso2(obj)
            % Implementación del paso 2
            n = length(obj.lista);
            if n==0
                if obj.zstar == inf
                    obj.info("Paso 2: No quedan problemas en la lista y z*=inf. -> Problema infactible")
                    obj.exitflag = -2;
                    obj.stop = true;
                else
                    obj.info("Paso 2: Solucion óptima")
                    obj.info(strcat("Paso 2: x*=[",num2str(obj.xstar'),"], z*=",num2str(obj.zstar)))
                    obj.exitflag = 1;
                    obj.stop = true;
                end
            elseif n == 1
                obj.info(strcat("Paso 2: queda ",num2str(length(obj.lista))," problema en la lista"))
            else
                obj.info(strcat("Paso 2: quedan ",num2str(length(obj.lista))," problemas en la lista"))
            end
        end
        function paso3(obj)
            % Implementación del paso 3.
            % Pendiente: refactorizar los bucles.
            n = length(obj.lista);
            zetas = ones(1,n)*inf;
            listanueva = {};
            for i = 1:n
                P = obj.lista{i};
                if isempty(P.exitflag)
                    P.resolverRelajado();
                end
                if P.exitflag==1
                    zetas(i)=P.zbar;
                    s = "Paso 3: Solución del problema ";
                    s = strcat(s,P.tag,": x=[",num2str(P.xbar'));
                    s = strcat(s,"]; z=",num2str(P.zbar));
                    obj.info(s);
                end
                if P.exitflag==-2
                    s = "Paso 3: El problema ";
                    s = strcat(s,P.tag," es infactible");
                    obj.info(s);
                end
            end
            [m,indice]=min(zetas);
            if m < inf
                obj.S = obj.lista{indice};
                obj.info(strcat("Paso 3: el problema con mejor solucion es el ",obj.S.tag))
                obj.info("Paso 3: se elige el problema y se quita de la lista");
            else
                obj.info("Paso 3: la lista se queda vacía (todos los subproblemas son infactibles o no acotados)");
                obj.stop = true;
                obj.exitflag = -2;
            end
            for i = 1:n
                P = obj.lista{i};
                if zetas(i) == inf
                    obj.info(strcat("Paso 3: se elimina el problema ",P.tag," por ser infactible"))
                elseif i ~= indice
                    listanueva{length(listanueva)+1} = P;
                end
            end
            obj.lista = listanueva;
        end
        function cambio = paso5(obj)
            % Implementación del paso 5. Devuelve true si se modifica el problema S.
            cambio = false;
            for i = 1:length(obj.hiperplanos) 
                plano = obj.hiperplanos{i};
                coeficientes = plano{1};
                termino = plano{2};
                if round(coeficientes*obj.S.xbar,10) > termino
                    cambio = true;
                    obj.info(strcat("Paso 5: se añade la restricción del plano ",num2str(i)))
                    obj.S.A(end+1,:) = coeficientes;
                    obj.S.b = [obj.S.b termino];
                end
            end
            if ~cambio
                obj.info("Paso 5: xbarra cumple todas las restricciones de los ciclados.")
            end
        end
        function result = paso6(obj)
            % Implementación del paso 6. Devuelve true si hay que ir al paso 2.
            result = false;
            if obj.S.c*obj.S.xbar >= obj.zstar
                obj.info("Paso 6: xbar*c >= z* --> Paso 2")
                result = true;
            end
            f = obj.S.xbar-floor(obj.S.xbar);
            f = f(obj.S.J);
            if f == zeros(length(f),1);
                obj.info("Paso 6: las variables xbarra_j son enteras para todo j en J --> Paso 2")
                obj.xstar = obj.S.xbar;
                obj.zstar = obj.S.c*obj.S.xbar;
                obj.info(strcat("Paso 6: se actualiza x* a xbarra = ",num2str(obj.S.xbar')))
                obj.info(strcat("Paso 6: se actualiza z* a c'*xbarra = ",num2str(obj.zstar)))
                result = true;
            end
            if ~result
                obj.info("Paso 6: no se cumple ninguna condición por lo que se va al paso 7.")
            end
        end
        function paso7(obj)
            % Implementación del paso 7.
            % En este paso se ramifica por una variable que debe ser entera y todavía no lo es.
            n = length(obj.S.c);
            f = obj.S.xbar-floor(obj.S.xbar);
            m = ones(1,n)*(-inf);
            for j = obj.S.J
                if f(j) > 0;
                    m(j) = min([f(j),1-f(j)]);
                    if round(m(j),10) == 0;
                        m(j) = -inf;
                    end
                end
            end
            [v,k] = max(m);
            obj.info(strcat("Paso 7: se ramifica por x",num2str(k)));
            A = [obj.S.A; zeros(1,n)];
            A(end,k) = 1;
            b = [obj.S.b floor(obj.S.xbar(k))];
            S1 = problema(obj.S.c,A,b,obj.S.Aeq,obj.S.beq,obj.S.lb,obj.S.ub,obj.S.J,obj.S.J0,strcat(obj.S.tag,"1"));
            A = [obj.S.A; zeros(1,n)];
            A(end,k) =-1;
            b(end) = -floor(obj.S.xbar(k)+1);
            S2 = problema(obj.S.c,A,b,obj.S.Aeq,obj.S.beq,obj.S.lb,obj.S.ub,obj.S.J,obj.S.J0,strcat(obj.S.tag,"2"));
            obj.ramif = [obj.ramif k];
            obj.lista{end+1} = S1;
            obj.lista{end+1} = S2;
            if obj.v
                disp("Paso 7: se añaden los siguientes problemas a la lista");
                disp(" ")
                disp(S1);
                disp(" ")
                disp(S2);
                disp(" ")
            end
        end
        function result = confirmar(obj)
            if obj.v & obj.inter
                result = true;
            else
                result = false;
            end
        end
        function info(obj,string)
            if obj.v
                disp(string);
            end
        end
        function s = lista2str(obj)
            s = "Lista =";
            for i = 1:length(obj.lista)
                P = obj.lista{i};
                s = strcat(s," ",P.tag);
            end
        end
	end
end
