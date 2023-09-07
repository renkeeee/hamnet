//
//  processTools.c
//  hamnet
//
//  Created by deepread on 2020/12/1.
//

#include "processTools.h"
#include <libproc.h>
#include <stdlib.h>
#include <strings.h>

int get_pid_with_port(int port) {
    int pid_num = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    int *pid_buffer = malloc(pid_num*sizeof(int));
    pid_num = proc_listpids(PROC_ALL_PIDS, 0, pid_buffer, pid_num*sizeof(int));
    
    for(int i = 0; i < pid_num; i++) {
        int pid = pid_buffer[i];
        int pid_info_buffer_size = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, 0, 0);
        if (pid_info_buffer_size == -1) {
            printf("unable get proc dfs with pid:%d \n", pid);
            free(pid_buffer);
            return -1;
        }
        
        struct proc_fdinfo *pid_fdinfos = (struct proc_fdinfo *)malloc(pid_info_buffer_size);
        if (!pid_fdinfos) {
            printf("out of memo with pid:%d \n", pid);
            free(pid_buffer);
            free(pid_fdinfos);
            return -1;
        }
        proc_pidinfo(pid, PROC_PIDLISTFDS, 0, pid_fdinfos, pid_info_buffer_size);
        int pid_fd_nums = pid_info_buffer_size / PROC_PIDLISTFD_SIZE;
        
        for (int j = 0; j < pid_fd_nums; j++) {
            if (pid_fdinfos[j].proc_fdtype == PROX_FDTYPE_SOCKET) {
                struct socket_fdinfo socket_info;
                int bytes_used = proc_pidfdinfo(pid, pid_fdinfos[j].proc_fd, PROC_PIDFDSOCKETINFO, &socket_info, PROC_PIDFDSOCKETINFO_SIZE);
                if (bytes_used == PROC_PIDFDSOCKETINFO_SIZE) {
                    if (socket_info.psi.soi_family == AF_INET && socket_info.psi.soi_kind == SOCKINFO_TCP) {
                        int local_port = (int)ntohs(socket_info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
                        if (local_port == port) {
                            free(pid_buffer);
                            free(pid_fdinfos);
                            return pid;
                        }
                    }
                }
            }
        }
        free(pid_fdinfos);
    }
    free(pid_buffer);
    return -1;
}

char* get_path_with_pid(int pid) {
    char pathBuffer [PROC_PIDPATHINFO_MAXSIZE];
    bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
    proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
    long count = strlen(pathBuffer);
    char *buffer = malloc(sizeof(char)*(count + 1));
    strcpy(buffer, pathBuffer);
    return buffer;
}


