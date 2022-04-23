!
! Copyright (C) 2003-2021 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#define ZERO (0.D0,0.D0)
!-----------------------------------------------------------------------
subroutine sh_setup
  !-----------------------------------------------------------------------
  !
  !! As kcw_setup.f90 plus screening specific setups
  !
  !
  USE kinds,             ONLY : DP
  USE fft_base,          ONLY : dffts
  !
  USE units_lr,          ONLY : iuwfc
  USE control_flags,     ONLY : io_level
  USE buffers,           ONLY : open_buffer, save_buffer, close_buffer
  USE control_kcw,       ONLY : iurho_wann, kcw_iverbosity, x_q, lgamma_iq, &
                                num_wann, nqstot, occ_mat, tmp_dir_kcw, tmp_dir_kcwq
  USE io_global,         ONLY : stdout
  USE klist,             ONLY : xk, nkstot
  USE cell_base,         ONLY : at !, bg
  USE fft_base,          ONLY : dffts
  !
  USE mp,                ONLY : mp_bcast
  USE io_kcw,            ONLY : read_rhowann
  !
  USE coulomb,           ONLY : setup_coulomb
  !
  implicit none
  !
  integer :: i
  ! counters
  !
  INTEGER   :: lrrho, iun_qlist
  ! Lenght record sor wfc and density, io_iunit for the list of q-points
  !
  LOGICAL   :: exst
  ! Check on the existence of the buffers
  !
  INTEGER :: iq, nqs
  ! Counters on the q points, total number of q points
  !
  REAL(DP) :: xq(3)
  ! the q-point coordinatew
  !
  COMPLEX(DP), ALLOCATABLE :: rhowann(:,:), rhowann_aux(:)
  ! the periodic part of the wannier orbital density
  !
  CHARACTER (LEN=256) :: file_base
  CHARACTER (LEN=6), EXTERNAL :: int_to_char
  !
  ! ... Open a buffer for the wannier orbital densities. Those have been written by wann2kcw
  ! ... and must be in the outdir. If not STOP
  !
  iurho_wann = 22
  io_level = 1
  lrrho=num_wann*dffts%nnr
  CALL open_buffer ( iurho_wann, 'rho_wann', lrrho, io_level, exst )
  if (kcw_iverbosity .gt. 1) WRITE(stdout,'(/,5X, "INFO: Buffer for WF rho, OPENED")')
  !
  ALLOCATE (rhowann ( dffts%nnr, num_wann), rhowann_aux(dffts%nnr) )
  ALLOCATE ( occ_mat (num_wann, num_wann, nkstot) )
  !
  ! ... Set up the coulomb kernel. If l_vcut=.true. the Gygi Balderschi scheme is used.
  ! ... Otherwise the g=0 component is set to zero 
  !
  call setup_coulomb()
  !
  ! ... Read the q-point grid written by wann2kcw
  !
  WRITE( stdout, '(/, 5X,"INFO: READING Wannier-orbital Densities ...")') 
  !
  iun_qlist = 127
  OPEN (iun_qlist, file = TRIM(tmp_dir_kcw)//'qlist.txt')
  !
  READ(iun_qlist,'(i5)') nqs
  nqstot = nqs
  !
  ALLOCATE (x_q (3, nqs) ) 
  ALLOCATE ( lgamma_iq(nqs) )
  lgamma_iq(:) = .FALSE.
  !
  DO iq = 1, nqs
    !! For each q in the mesh 
    !
    READ (127,'(3f12.8)') xq
    x_q(:,iq) = xq ! Store the q vectors
    lgamma_iq(iq)=(x_q(1,iq)==0.D0.AND.x_q(2,iq)==0.D0.AND.x_q(3,iq)==0.D0)
    CALL cryst_to_cart(1, xq, at, -1)
    !
    IF (kcw_iverbosity .gt. 1) THEN
      WRITE( stdout,'(/,8X, 78("="))')
      WRITE( stdout, '( 8X, "iq = ", i5)') iq
      WRITE( stdout, '( 8X,"The  Wannier density at  q = ",3F12.7, "  [Cart ]")')  xk(:,iq)
      WRITE( stdout, '( 8X,"The  Wannier density at  q = ",3F12.7, "  [Cryst]")')  xq(:)
      WRITE( stdout, '( 8X, 78("="),/)')
    ENDIF
    ! 
    tmp_dir_kcwq= TRIM (tmp_dir_kcw) // 'q' &
                & // TRIM(int_to_char(iq))//'/'
    !
    DO i = 1, num_wann
      file_base=TRIM(tmp_dir_kcwq)//'rhowann_iwann_'//TRIM(int_to_char(i))
      CALL read_rhowann( file_base, dffts, rhowann_aux )
      rhowann(:,i) = rhowann_aux(:)
    ENDDO
    !
    ! ... Save the rho_q on a direct access file
    !
    lrrho=num_wann*dffts%nnr
    CALL save_buffer (rhowann, lrrho, iurho_wann, iq)
    !
  ENDDO
  !
  WRITE( stdout, '(/, 5X,"INFO: READING Wannier-orbital Densities ... DONE")') 
  !
  !
  CALL close_buffer  ( iuwfc, 'KEEP' )
  !
  DEALLOCATE (rhowann, rhowann_aux)
  !
  RETURN
  !
END SUBROUTINE sh_setup
