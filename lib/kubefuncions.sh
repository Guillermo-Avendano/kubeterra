#!/bin/bash
# Function to install dependencies based on OS


debug_namespaces(){

    log_dir="logs"

    if [ ! -d "$log_dir" ]; then
       mkdir -p "$log_dir"
    else
       rm -f $log_dir/*.*
    fi

    # Declarar el array
    declare -a KUBE_NS_LIST=()

    # Obtener namespaces y filtrar los que NO contengan 'kube' ni 'ingress'
    while IFS= read -r ns; do
        # Ignorar líneas vacías
        [[ -z "$ns" ]] && continue
        # Filtrar namespaces que NO contengan 'kube' ni 'ingress' (insensible a mayúsculas)
        if [[ ! "${ns,,}" =~ kube && ! "${ns,,}" =~ ingress  && ! "${ns,,}" =~ default  ]]; then
            KUBE_NS_LIST+=("$ns")
        fi
    done < <(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

    # Exportar el array
    export KUBE_NS_LIST
    
    for namespace in "${KUBE_NS_LIST[@]}"
        do
            log INFO "Namespace: $namespace"

            pods=$(kubectl -n $namespace get pods -o custom-columns=:metadata.name)

            for pod_name in $pods
            do
                # Obtener la cantidad de contenedores en el pod
                container_count=$(kubectl -n $namespace get pod $pod_name -o jsonpath='{.spec.containers[*].name}' | wc -w)

                # Guardar información del pod, independientemente del número de contenedores
                kubectl -n $namespace set env pod/$pod_name --list > $log_dir/${namespace}_${pod_name}_POD_ENV.txt
                kubectl -n $namespace get pod/$pod_name -o yaml > $log_dir/${namespace}_${pod_name}_POD_GET.yaml 
                kubectl -n $namespace describe pod/$pod_name > $log_dir/${namespace}_${pod_name}_POD_DESCRIBE.txt

                if [ "$container_count" -eq 1 ]; then
                    # Si el pod tiene un solo contenedor
                    kubectl -n $namespace logs pod/$pod_name > $log_dir/${namespace}_${pod_name}_POD_LOG.txt
                else
                    # Si el pod tiene múltiples contenedores
                    containers=$(kubectl -n $namespace get pod $pod_name -o jsonpath='{.spec.containers[*].name}')
                    for container_name in $containers
                    do
                        kubectl -n $namespace logs pod/$pod_name -c $container_name > $log_dir/${namespace}_${pod_name}_${container_name}_POD_LOG.txt
                    done
                fi
            done

            services=$(kubectl -n $namespace get services --output=name)

            for srv in $services
                do
                srv_name=$(echo $srv | cut -d/ -f2) 

                kubectl -n $namespace get service/$srv_name -o yaml > $log_dir/${namespace}_${srv_name}_SERVICE_GET.yaml 
                kubectl -n $namespace describe service/$srv_name    > $log_dir/${namespace}_${srv_name}_SERVICE_DESCRIBE.txt

                done

            endpointslice=$(kubectl -n $namespace get endpointslice --output=name)

            for eps in $endpointslice
                do
                eps_name=$(echo $eps | cut -d/ -f2) 

                kubectl -n $namespace get endpointslice/$eps_name -o yaml > $log_dir/${namespace}_${eps_name}_END_POINT_SLICE_GET.yaml 
                kubectl -n $namespace describe endpointslice/$eps_name    > $log_dir/${namespace}_${eps_name}_END_POINT_SLICE_DESCRIBE.txt

                done


            ingresses=$(kubectl -n $namespace get ingress --output=name)

            for ingress in $ingresses
                do
                ingress_name=$(echo $ingress | cut -d/ -f2) 

                kubectl -n $namespace get ingress/$ingress_name -o yaml > $log_dir/${namespace}_${ingress_name}_INGRESS_GET.yaml 
                kubectl -n $namespace describe ingress/$ingress_name    > $log_dir/${namespace}_${ingress_name}_INGRESS_DESCRIBE.txt

                done

            secrets=$(kubectl -n $namespace get secret --output=name)

            for secret in $secrets
                do
                secret_name=$(echo $secret | cut -d/ -f2) 

                if [[ ! "$secret_name" == *".helm."* ]]; then
                    kubectl -n $namespace get secret/$secret_name -o yaml > $log_dir/${namespace}_${secret_name}_SECRET_GET.yaml 
                    #kubectl -n $namespace describe secret/$secret_name    > $log_dir/${namespace}_${secret_name}_DESCRIBE_SECRET.txt
                fi
                done
          
            pvcs=$(kubectl -n $namespace get pvc --output=name)

            for pvc in $pvcs
                do
                pvc_name=$(echo $pvc | cut -d/ -f2) 

                if [[ ! "$pvc_name" == *".helm."* ]]; then
                    kubectl -n $namespace get persistentvolumeclaim/$pvc_name -o yaml > $log_dir/${namespace}_${pvc_name}_PVC_GET.yaml 
                    kubectl -n $namespace describe persistentvolumeclaim/$pvc_name  > $log_dir/${namespace}_${pvc_name}_PVC_DESCRIBE.txt
                fi
                done
        done

        log INFO "Debug files in ./$log_dir"

}



