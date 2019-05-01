class Nwchem < Formula
  desc "NWChem: Open Source High-Performance Computational Chemistry"
  homepage "http://www.nwchem-sw.org"
  url "https://github.com/nwchemgit/nwchem/releases/download/6.8.1-release/nwchem-6.8.1-release.revision-v6.8-133-ge032219-src.2018-06-14.tar.bz2"
  version "6.8.1"
  sha256 "23ce8241a5977a93d8224f66433851c81a08ad58a4c551858ae031485b095ab7"
  revision 6

  bottle do
    cellar :any
    rebuild 1
    sha256 "112e8db94247839d66192a4b94bd2c4fc74b8449560b96260d700eb26869525e" => :mojave
    sha256 "2ae8c976947067d207ec09455be366fa1ecfdc2602d603f1b52126269bb0fe40" => :high_sierra
    sha256 "0e31d140731395351db046d277598db9f1bc1108b72bff6756921159ec5a04eb" => :sierra
  end

  depends_on "gcc" # for gfortran
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "scalapack"

  def install
    pkgshare.install "QA"

    cd "src" do
      (prefix/"etc").mkdir
      (prefix/"etc/nwchemrc").write <<~EOS
        nwchem_basis_library #{pkgshare}/libraries/
        nwchem_nwpw_library #{pkgshare}/libraryps/
        ffield amber
        amber_1 #{pkgshare}/amber_s/
        amber_2 #{pkgshare}/amber_q/
        amber_3 #{pkgshare}/amber_x/
        amber_4 #{pkgshare}/amber_u/
        spce    #{pkgshare}/solvents/spce.rst
        charmm_s #{pkgshare}/charmm_s/
        charmm_x #{pkgshare}/charmm_x/
      EOS

      inreplace "util/util_nwchemrc.F", "/etc/nwchemrc", "#{etc}/nwchemrc"

      ENV["NWCHEM_TOP"] = buildpath
      ENV["PYTHONVERSION"] = "2.7"
      pyhome = `python-config --prefix`.chomp
      ENV["PYTHONHOME"] = pyhome
      ENV["NWCHEM_LONG_PATHS"] = "Y"
      ENV["BLASOPT"] = "-L#{Formula["openblas"].opt_lib} -lopenblas"
      ENV["BLAS_SIZE"] = "4"
      ENV["SCALAPACK"] = "-L#{Formula["scalapack"].opt_prefix}/lib -lscalapack"
      ENV["USE_64TO32"] = "y"
      system "make", "nwchem_config", "NWCHEM_MODULES=all python"
      system "make", "64_to_32"
      system "make", "NWCHEM_TARGET=MACX64", "USE_MPI=Y"

      bin.install "../bin/MACX64/nwchem"
      pkgshare.install "basis/libraries"
      pkgshare.install "nwpw/libraryps"
      pkgshare.install Dir["data/*"]
    end
  end

  test do
    cp_r pkgshare/"QA", testpath
    cd "QA" do
      ENV["NWCHEM_TOP"] = pkgshare
      ENV["NWCHEM_TARGET"] = "MACX64"
      ENV["NWCHEM_EXECUTABLE"] = "#{bin}/nwchem"
      system "./runtests.mpi.unix", "procs", "0", "dft_he2+", "prop_mep_gcube", "pspw", "tddft_h2o", "tce_n2"
    end
  end
end
