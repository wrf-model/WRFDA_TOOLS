;*************************************************************************
; NCL script for adding v4.0 information to legacy WRF input/output files:
;    + vectors for hybrid coordinate
;    + namelist attributes for HYBRID_OPT, THETA_M, ETAC
;
;        Author: Jonathan Guerrette
;        Date  : 07/10/2019
;
;
;****************************************************************
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"


begin

   ;Create list of input files to modify
   WRKDIR = "/top/level/work/directory/"
   CHILDDIR = ""
   CHILDDIR = "*/*"

   FILETYPES = (/"wrfinput_d01", "fg", "wrfvar_output", "wrfout"/)
   DATA_DIRECTORY = WRKDIR+CHILDDIR +"/"

   command = "ls "
   ntype = dimsizes(FILETYPES)
   do ifile = 0, ntype-1
      command = command +DATA_DIRECTORY+FILETYPES(ifile) +"* "
   end do

   print(command)
   FILELIST  = systemfunc(command)
   print(FILELIST)

   VERT_VARS = (/ \
                 (/"ZNW","C1F","C2F","C3F","C4F"/), \
                 (/"ZNU","C1H","C2H","C3H","C4H"/) \
               /)

   VERT_DESC = (/ \
                 (/ \
                    "full levels, c1f = d bf / d eta, using znu", \
                    "full levels, c2f = (1-c1f)*(p0-pt)", \
                    "full levels, c3f = bf", \
                    "full levels, c4f = (eta-bf)*(p0-pt)+pt, using znw" \
                 /), \
                 (/ \
                    "half levels, c1h = d bf / d eta, using znw", \
                    "half levels, c2h = (1-c1h)*(p0-pt)", \
                    "half levels, c3h = bh", \
                    "half levels, c4h = (eta-bh)*(p0-pt)+pt, using znu" \
                 /) \
              /)

   numfiles=dimsizes(FILELIST)
   numvars=dimsizes(VERT_VARS)

   HYBRID_OPT = 0
   USE_THETA_M = 0
   ETAC = 0.0
   ;ETAC = todouble(0.0)

   do ifile = 0, numfiles(0)-1
      print("Working on "+FILELIST(ifile))
      wrfinput_d01 = addfile(FILELIST(ifile)+".nc","w")
      wrfinput_d01@HYBRID_OPT = HYBRID_OPT
      wrfinput_d01@ETAC = ETAC
      wrfinput_d01@USE_THETA_M = USE_THETA_M

      THM = wrfinput_d01->T
      THM@description = "perturbation moist potential temperature (1+Rv/Rd Qv)*(theta-t0)"
      THM@units = "K"
      wrfinput_d01->$"THM"$ = THM
      delete(THM)

      do ivar1 = 0, numvars(0)-1
         VAR1 = wrfinput_d01->$VERT_VARS(ivar1,0)$

         do ivar2 = 1, numvars(1)-1
            VAR2 = VAR1
            if (ivar2 .eq. 1) then ; C1
               VAR2(0,:) = 1.0
               VAR2@units = "Dimensionless"
            else if (ivar2 .eq. 2) then ; C2
               VAR2(0,:) = 0.0
               VAR2@units = "Pa"
            else if (ivar2 .eq. 3) then ; C3
               VAR2@units = "Dimensionless"
            else if (ivar2 .eq. 4) then ; C4
               VAR2(0,:) = 0.0
               VAR2@units = "Pa"
            end if
            end if
            end if
            end if
            VAR2@description = VERT_DESC(ivar1,ivar2-1)

            wrfinput_d01->$VERT_VARS(ivar1,ivar2)$ = VAR2

            delete(VAR2)
         end do
         delete(VAR1)
      end do
      delete(wrfinput_d01)
   end do

end
