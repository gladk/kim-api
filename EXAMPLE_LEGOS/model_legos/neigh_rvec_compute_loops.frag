    !  Compute energy and forces
    !
    do i = 1,numberOfAtoms
       
       ! Get neighbors for atom i
       !
       atom = i ! request neighbors for atom i
       ier = kim_api_get_full_neigh(pkim,1,atom,atom_ret,numnei,pnei1atom,pRij)
       if (ier.le.0) then
          call report_error(__LINE__, "kim_api_get_full_neigh", ier);
          return
       endif

       
       ! Loop over the neighbors of atom i
       !
       do jj = 1, numnei
          Rsqij = dot_product(Rij(:,jj),Rij(:,jj))         ! compute square distance
          if ( Rsqij < model_cutsq ) then                  ! particles are interacting?
             r = sqrt(Rsqij)                               ! compute distance
             call pair(model_epsilon,model_sigma,model_A,model_B, model_C, &
                  r,phi,dphi,d2phi)                        ! compute pair potential
             if (comp_enepot.eq.1) then                    !
                ene_pot(i) = ene_pot(i) + 0.5d0*phi        ! accumulate energy
             else                                          !
                energy = energy + 0.5d0*phi                ! full neigh case
             endif                                         !
             if (comp_virial.eq.1) then                    !
                virial = virial + 0.5d0*r*dphi             ! accumul. virial=sum r(dV/dr)
             endif                                         !
             if (comp_force.eq.1) then                     !
                force(:,i) = force(:,i) - dphi*Rij(:,jj)/r ! accumulate forces
             endif
          endif
       enddo
    enddo