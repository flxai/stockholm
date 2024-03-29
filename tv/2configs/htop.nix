with import ./lib;
{ pkgs, ... }: {
  nixpkgs.config.packageOverrides = super: {
    htop = pkgs.symlinkJoin {
      name = "htop";
      paths = [
        (pkgs.writeDashBin "htop" ''
          export HTOPRC=${pkgs.writeText "htoprc" ''
            fields=0 48 17 18 38 39 40 2 46 47 49 1
            sort_key=46
            sort_direction=1
            hide_threads=0
            hide_kernel_threads=1
            hide_userland_threads=0
            shadow_other_users=1
            show_thread_names=1
            show_program_path=1
            highlight_base_name=1
            highlight_megabytes=1
            highlight_threads=1
            tree_view=1
            header_margin=0
            detailed_cpu_time=0
            cpu_count_from_zero=0
            update_process_names=0
            account_guest_in_cpu_meter=1
            color_scheme=0
            delay=15
            left_meters=LeftCPUs2 RightCPUs2 Memory Swap
            left_meter_modes=1 1 1 1
            right_meters=Uptime Tasks LoadAverage Battery
            right_meter_modes=2 2 2 2
          ''}
          exec ${super.htop}/bin/htop "$@"
        '')
        super.htop
      ];
    };
  };
}
