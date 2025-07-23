module peony

pub struct Blobly {
}

pub fn new_provider_blob_blobly(pk string, sk string) Blobly {
	return Blobly{}
}

fn (b Blobly) create(f FileRequest) !FileData {
	return error('TODO')
}

fn (b Blobly) delete(f []string) ! {
	return error('TODO')
}
