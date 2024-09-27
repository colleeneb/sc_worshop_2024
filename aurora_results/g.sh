#!/usr/bin/env bash

display_help() {
  echo " Will map gpu tile to rank in compact and then round-robin fashion"
  echo " Usage:"
  echo "   mpiexec -np N gpu_tile_compact.sh ./a.out"
  echo
  echo " Example 3 GPU of 2 Tiles with 7 Ranks:"
  echo "   0 Rank 0.0" 0
  echo "   1 Rank 0.1" 1
  echo "   2 Rank 1.0" 2
  echo "   3 Rank 1.1" 3
  echo "   4 Rank 2.0" 4
  echo "   5 Rank 2.1" 5
  echo "   6 Rank 0.0" 6
  echo 
  echo " Hacked together by apl@anl.gov, please contact if bug found"
  exit 1
}

#This give the exact GPU count i915 knows about and I use udev to only enumerate the devices with physical presence.
num_gpu=$(/usr/bin/udevadm info /sys/module/i915/drivers/pci:i915/* |& grep -v Unknown | grep -c "P: /devices")
num_tile=2

if [ "$#" -eq 0 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$num_gpu" = 0 ] ; then
  display_help
fi

# Get the RankID from different launcher
if [[ -v MPI_LOCALRANKID ]]; then
  _MPI_RANKID=$MPI_LOCALRANKID 
elif [[ -v PALS_LOCAL_RANKID ]]; then
  _MPI_RANKID=$PALS_LOCAL_RANKID
else
  display_help
fi

gpu_id=$(((_MPI_RANKID / 4) % num_gpu))
tile_id=$(((_MPI_RANKID / 2) % 2))

unset EnableWalkerPartition
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1
export ZE_AFFINITY_MASK=$gpu_id.$tile_id

#module load spack thapi
#set -x

echo "$_MPI_RANKID on $gpu_id.$tile_id"
"$@"
