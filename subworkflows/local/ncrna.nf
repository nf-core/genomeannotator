include { INFERNAL_PRESS } from '../../modules/local/infernal/press'
include { INFERNAL_SEARCH } from '../../modules/local/infernal/search'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { HELPER_RFAMTOGFF } from '../../modules/local/helper/rfamtogff'
include { GUNZIP as GUNZIP_RFAM_CM; GUNZIP as GUNZIP_RFAM_FAMILY } from '../../modules/nf-core/modules/gunzip/main'

workflow NCRNA {

   take:
   genome
   rfam_cm_gz
   rfam_family_gz

   main:
   FASTASPLITTER(
      genome,
      params.npart_size
   )

   GUNZIP_RFAM_CM(
      create_file_channel(rfam_cm_gz)
   )
   
   GUNZIP_RFAM_FAMILY(
      create_file_channel(rfam_family_gz)
   )

   INFERNAL_PRESS(
      GUNZIP_RFAM_CM.out.gunzip.map {m,f -> f}
   )
  
   INFERNAL_SEARCH(
      FASTASPLITTER.out.chunks,
      INFERNAL_PRESS.out.cm.collect()
   )

    INFERNAL_SEARCH.out.tbl
    .multiMap { m,t ->
       metadata: [m.id, m]
       tbl: [m.id,t ]
    }.set { ch_rfam_tbls }

    ch_rfam_tbls.tbl.collectFile { mkey, file -> [ "${mkey}.rfam.gff", file ] }
    .map { file -> [ file.simpleName, file ] }
    .set { ch_merged_tbls }

    ch_rfam_tbls.metadata.join(
       ch_merged_tbls
    )
    .map { k,m,f -> tuple(m,f) }
    .set { ch_rfam_gff }
   
   HELPER_RFAMTOGFF(
      ch_rfam_gff,
      GUNZIP_RFAM_FAMILY.out.gunzip.map{m,f -> f}
   )

   emit:
   gff = HELPER_RFAMTOGFF.out.gff

}

def create_file_channel(f) {
    def meta = [:]
    meta.id           = file(f).getSimpleName()

    def array = [ meta, f ]

    return array
}

