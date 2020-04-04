!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
! Author: L. Martin-Samos
!
!----------------------------------------------------------------------------
SUBROUTINE openfil_all_currents()
  !----------------------------------------------------------------------------
  !
  ! ... This routine opens all files needed to the self consistent run,
  ! ... sets various file names, units, record lengths
  !
  USE kinds,          ONLY : DP
  USE wvfct,          ONLY : nbnd, npwx
  !use control_flags,  ONLY:  twfcollect
  USE io_files,       ONLY : prefix, iunwfc, nwordwfc, iunat => iunhub, iunsat, &
                             diropn, nwordatwfc, tmp_dir
  USE noncollin_module, ONLY : npol, noncolin
  USE ldaU,             ONLY : lda_plus_u
  USE basis,            ONLY : natomwfc
  USE uspp_param,       ONLY : n_atom_wfc
  USE ions_base,        ONLY : nat, ityp
  !
  IMPLICIT NONE
  !
  LOGICAL       :: exst
  !
  !twfcollect=.false.
  !
  ! ... nwordwfc is the record length for the direct-access file
  ! ... containing wavefunctions
  !
  !  print*,'nword',nwordwfc
  nwordwfc = nbnd * npwx * npol
  !  print*,'nxnx',nwordwfc
  !
  CALL diropn( iunwfc, 'wfc', 2 * nwordwfc, exst, tmp_dir )
  ! 
  IF ( .NOT. exst ) THEN
     call errore ('openfil_all_currents','file '//TRIM( prefix )//'.wfc'//' not found',1)
  END IF
  !
  !!!! ... iunigk contains the number of PW and the indices igk
  !!!! ... Note that unit 15 is reserved for error messages
  !
  !!!! CALL seqopn( iunigk, 'igk', 'UNFORMATTED', exst )
  !!!!
  !!!! IF ( .NOT. exst ) THEN
  !!!!   call errore ('openfil_pp','file '//TRIM( prefix )//'.igk'//' not found',1)
  !!!! END IF
  !
  ! ... Needed for LDA+U
  !
  ! ... iunat  contains the (orthogonalized) atomic wfcs
  ! ... iunsat contains the (orthogonalized) atomic wfcs * S
  ! ... iunocc contains the atomic occupations computed in new_ns
  ! ... it is opened and closed for each reading-writing operation
  !
  natomwfc = n_atom_wfc( nat, ityp, noncolin )
  nwordatwfc = 2*npwx*natomwfc*npol
  !
  IF ( lda_plus_u ) then
     CALL diropn( iunat,  'atwfc',  nwordatwfc, exst, tmp_dir )
     IF ( .NOT. exst ) THEN
        call errore ('openfil_all_currents','file '//TRIM( prefix )//'.atwfc'//' not found',1)
     END IF

     CALL diropn( iunsat, 'satwfc', nwordatwfc, exst, tmp_dir )
     IF ( .NOT. exst ) THEN
        call errore ('openfil_all_currents','file '//TRIM( prefix )//'.satwfc'//' not found',1)
     END IF
  END IF
  !

  RETURN
  !
END SUBROUTINE openfil_all_currents
