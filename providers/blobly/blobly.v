module blobly

import einar_hjortdal.peony

pub struct Blobly {
}

fn new_blobly(pk string, sk string) Blobly {
}

fn (b Blobly) create(f FileRequest) !FileData {
}

fn (b Blobly) delete(f []string) ! {}
